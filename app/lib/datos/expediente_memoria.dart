import 'dart:convert';
import 'dart:math';

import '../dominio/bandeja_salida.dart' show Evento;
import '../dominio/expediente/almacen.dart';
import '../dominio/expediente/claves.dart';

/// Eventos en memoria. Se guardan como texto, así que lo que devuelve [leer] es siempre una copia.
///
/// Sirve para las pruebas y para el arranque sin almacenamiento. El expediente en disco se hará sobre Drift.
class AlmacenEventosMemoria implements AlmacenEventos {
  final Map<String, List<String>> _flujos = {};
  final Set<String> _ids = {};

  @override
  Future<void> anexar(String flujo, Evento evento) async {
    final id = evento['event_id'] as String;
    if (!_ids.add(id)) {
      throw StateError('el evento $id ya está en el expediente');
    }
    _flujos.putIfAbsent(flujo, () => <String>[]).add(jsonEncode(evento));
  }

  @override
  Future<List<Evento>> leer(String flujo) async {
    final textos = _flujos[flujo] ?? const <String>[];
    return [for (final texto in textos) jsonDecode(texto) as Evento];
  }
}

/// Claves en memoria, una por usuario. Una vez destruida, la clave de un usuario no vuelve a crearse.
class AlmacenClavesMemoria implements AlmacenClaves {
  AlmacenClavesMemoria({Random? aleatorio}) : _aleatorio = aleatorio ?? Random.secure();

  final Random _aleatorio;
  final Map<String, List<int>> _claves = {};
  final Set<String> _destruidas = {};

  @override
  Future<List<int>> claveDeUsuario(String usuario) async {
    if (_destruidas.contains(usuario)) {
      throw ClaveDestruida(usuario);
    }
    final clave = _claves.putIfAbsent(
      usuario,
      () => List<int>.generate(32, (_) => _aleatorio.nextInt(256)),
    );
    return List<int>.unmodifiable(clave);
  }

  @override
  Future<void> destruirClave(String usuario) async {
    _claves.remove(usuario);
    _destruidas.add(usuario);
  }
}
