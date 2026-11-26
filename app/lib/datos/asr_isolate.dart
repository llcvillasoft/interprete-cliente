import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../dominio/asr.dart';
import '../dominio/asr_motor.dart';
import 'asr_whisper_nativo.dart';

/// Backend de whisper.cpp que vive en un isolate propio. La interfaz no se bloquea
/// mientras el modelo transcribe, y el modelo se carga una sola vez.
///
/// Las peticiones se atienden en orden. Cada una lleva un identificador, y la
/// respuesta vuelve con ese mismo identificador.
class WhisperEnIsolate implements BackendWhisper {
  WhisperEnIsolate._(this._recibidos);

  final ReceivePort _recibidos;
  final Completer<SendPort> _listo = Completer<SendPort>();
  final Map<int, Completer<List<RegistroWhisper>>> _pendientes = {};
  SendPort? _puerto;
  int _siguiente = 0;
  bool _cerrado = false;

  /// Arranca el isolate y carga el modelo. Lanza [StateError] si el modelo no abre.
  static Future<WhisperEnIsolate> abrir({
    required String rutaBiblioteca,
    required String rutaModelo,
    int hilos = 0,
  }) async {
    final recibidos = ReceivePort();
    final backend = WhisperEnIsolate._(recibidos);
    recibidos.listen(backend._alRecibir);
    await Isolate.spawn<(SendPort, String, String, int)>(
      _entrada,
      (recibidos.sendPort, rutaBiblioteca, rutaModelo, hilos),
    );
    try {
      await backend._listo.future;
    } catch (_) {
      backend.cerrar();
      rethrow;
    }
    return backend;
  }

  @override
  Future<List<RegistroWhisper>> transcribir(Float32List muestras, String idioma) async {
    if (muestras.isEmpty) {
      throw ArgumentError.value(muestras.length, 'muestras', 'No hay audio que reconocer');
    }
    final puerto = _puerto;
    if (_cerrado || puerto == null) {
      throw StateError('El reconocedor está cerrado');
    }
    final id = _siguiente++;
    final respuesta = Completer<List<RegistroWhisper>>();
    _pendientes[id] = respuesta;
    puerto.send((id, muestras, idioma));
    return respuesta.future;
  }

  /// Cierra el isolate y falla las peticiones que quedaron sin respuesta.
  void cerrar() {
    if (_cerrado) return;
    _cerrado = true;
    _puerto?.send(null);
    _recibidos.close();
    for (final pendiente in _pendientes.values) {
      if (!pendiente.isCompleted) {
        pendiente.completeError(StateError('El reconocedor se cerró antes de responder'));
      }
    }
    _pendientes.clear();
  }

  void _alRecibir(Object? mensaje) {
    if (!_listo.isCompleted) {
      if (mensaje is SendPort) {
        _puerto = mensaje;
        _listo.complete(mensaje);
      } else {
        _listo.completeError(StateError('$mensaje'));
      }
      return;
    }
    final respuesta = mensaje as Map<Object?, Object?>;
    final id = respuesta['id'] as int;
    final pendiente = _pendientes.remove(id);
    if (pendiente == null) return;
    final error = respuesta['error'];
    if (error != null) {
      pendiente.completeError(StateError('$error'));
      return;
    }
    final filas = respuesta['registros'] as List<Object?>;
    pendiente.complete([
      for (final fila in filas)
        (
          t0: (fila as List<Object?>)[0] as int,
          t1: fila[1] as int,
          texto: fila[2] as String,
        ),
    ]);
  }

  static void _entrada((SendPort, String, String, int) arranque) {
    final (puertoPrincipal, biblioteca, modelo, hilos) = arranque;
    final puertoPeticiones = ReceivePort();
    final WhisperNativo cargado;
    try {
      cargado = WhisperNativo.abrir(
        rutaBiblioteca: biblioteca,
        rutaModelo: modelo,
        hilos: hilos,
      );
    } catch (error) {
      puertoPrincipal.send('$error');
      puertoPeticiones.close();
      return;
    }
    puertoPrincipal.send(puertoPeticiones.sendPort);
    puertoPeticiones.listen((Object? mensaje) async {
      if (mensaje == null) {
        cargado.cerrar();
        puertoPeticiones.close();
        return;
      }
      final (id, muestras, idioma) = mensaje as (int, Float32List, String);
      try {
        final registros = await cargado.transcribir(muestras, idioma);
        puertoPrincipal.send({
          'id': id,
          'registros': [
            for (final registro in registros) [registro.t0, registro.t1, registro.texto],
          ],
        });
      } catch (error) {
        puertoPrincipal.send({'id': id, 'error': '$error'});
      }
    });
  }
}
