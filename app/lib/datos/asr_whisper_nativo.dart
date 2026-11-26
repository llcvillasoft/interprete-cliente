import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../dominio/asr.dart';
import '../dominio/asr_motor.dart';

final class _WcModel extends Opaque {}

final class _WcResult extends Opaque {}

typedef _LoadC = Int32 Function(Pointer<Utf8>, Int32, Pointer<Pointer<_WcModel>>);
typedef _Load = int Function(Pointer<Utf8>, int, Pointer<Pointer<_WcModel>>);

typedef _FreeC = Void Function(Pointer<_WcModel>);
typedef _Free = void Function(Pointer<_WcModel>);

typedef _TranscribeC = Int32 Function(
    Pointer<_WcModel>, Pointer<Float>, Uint32, Pointer<Utf8>, Pointer<Pointer<_WcResult>>);
typedef _Transcribe = int Function(
    Pointer<_WcModel>, Pointer<Float>, int, Pointer<Utf8>, Pointer<Pointer<_WcResult>>);

typedef _CountC = Int32 Function(Pointer<_WcResult>);
typedef _Count = int Function(Pointer<_WcResult>);

typedef _TimeC = Int64 Function(Pointer<_WcResult>, Int32);
typedef _Time = int Function(Pointer<_WcResult>, int);

typedef _TextC = Pointer<Utf8> Function(Pointer<_WcResult>, Int32);
typedef _Text = Pointer<Utf8> Function(Pointer<_WcResult>, int);

typedef _ResultFreeC = Void Function(Pointer<_WcResult>);
typedef _ResultFree = void Function(Pointer<_WcResult>);

/// Backend de whisper.cpp sobre `libwhisper_core`. Carga el modelo al abrirse.
///
/// La transcripción corre en el hilo que la llama. Antes de usarla en la interfaz
/// hay que moverla a un isolate, porque un modelo grande puede tardar varios segundos.
class WhisperNativo implements BackendWhisper {
  WhisperNativo._(this._biblioteca, this._modelo)
      : _liberar = _biblioteca.lookupFunction<_FreeC, _Free>('wc_free'),
        _transcribir = _biblioteca.lookupFunction<_TranscribeC, _Transcribe>('wc_transcribe'),
        _contar = _biblioteca.lookupFunction<_CountC, _Count>('wc_result_count'),
        _t0 = _biblioteca.lookupFunction<_TimeC, _Time>('wc_result_t0_cs'),
        _t1 = _biblioteca.lookupFunction<_TimeC, _Time>('wc_result_t1_cs'),
        _texto = _biblioteca.lookupFunction<_TextC, _Text>('wc_result_text'),
        _liberarResultado =
            _biblioteca.lookupFunction<_ResultFreeC, _ResultFree>('wc_result_free');

  /// Abre `libwhisper_core` y carga el modelo. Lanza [StateError] si el modelo no abre.
  static WhisperNativo abrir({
    required String rutaBiblioteca,
    required String rutaModelo,
    int hilos = 0,
  }) {
    final biblioteca = DynamicLibrary.open(rutaBiblioteca);
    final cargar = biblioteca.lookupFunction<_LoadC, _Load>('wc_load');
    final ruta = rutaModelo.toNativeUtf8();
    final salida = calloc<Pointer<_WcModel>>();
    try {
      final estado = cargar(ruta, hilos, salida);
      if (estado != 0) {
        throw StateError('No se pudo cargar el modelo de reconocimiento (código $estado)');
      }
      return WhisperNativo._(biblioteca, salida.value);
    } finally {
      calloc.free(salida);
      malloc.free(ruta);
    }
  }

  final DynamicLibrary _biblioteca;
  final Pointer<_WcModel> _modelo;
  final _Free _liberar;
  final _Transcribe _transcribir;
  final _Count _contar;
  final _Time _t0;
  final _Time _t1;
  final _Text _texto;
  final _ResultFree _liberarResultado;

  @override
  Future<List<RegistroWhisper>> transcribir(Float32List muestras, String idioma) async {
    if (muestras.isEmpty) {
      throw ArgumentError.value(muestras.length, 'muestras', 'No hay audio que reconocer');
    }
    final entrada = calloc<Float>(muestras.length);
    final idiomaNativo = idioma.toNativeUtf8();
    final salida = calloc<Pointer<_WcResult>>();
    try {
      entrada.asTypedList(muestras.length).setAll(0, muestras);
      final estado = _transcribir(_modelo, entrada, muestras.length, idiomaNativo, salida);
      if (estado != 0) {
        throw StateError('whisper.cpp no pudo transcribir (código $estado)');
      }
      final resultado = salida.value;
      try {
        final n = _contar(resultado);
        return [
          for (var i = 0; i < n; i++)
            (
              t0: _t0(resultado, i),
              t1: _t1(resultado, i),
              texto: _texto(resultado, i).toDartString(),
            ),
        ];
      } finally {
        _liberarResultado(resultado);
      }
    } finally {
      malloc.free(idiomaNativo);
      calloc.free(salida);
      calloc.free(entrada);
    }
  }

  /// Libera el modelo. No se usa el objeto después de cerrarlo.
  void cerrar() => _liberar(_modelo);
}
