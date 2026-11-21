import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'nucleo_audio_tipos.dart';

/// Abre el motor con `libaudio_core`. Con [ruta] nula usa la de la plataforma.
MotorAudio abrirMotorAudio({
  ConfiguracionAudio config = const ConfiguracionAudio(),
  String? ruta,
}) =>
    MotorAudioNativo.abrir(config, ruta: ruta);

/// `ac_status` de éxito y de "no cabe ahora" o "todavía no ha sonado".
const int _ok = 0;
const int _errEstado = -4;

final class _AcEngine extends Opaque {}

final class _AcConfig extends Struct {
  @Uint32()
  external int frecuenciaMuestreo;

  @Uint32()
  external int tamanoPeriodo;

  @Uint32()
  external int capacidadReproduccion;

  @Uint32()
  external int capacidadCaptura;

  @Int32()
  external int backendNulo;
}

final class _AcInfo extends Struct {
  @Uint32()
  external int frecuenciaMuestreo;

  @Uint32()
  external int canales;

  @Uint32()
  external int latenciaEntradaFramas;

  @Uint32()
  external int latenciaSalidaFramas;
}

typedef _OpenC = Int32 Function(Pointer<_AcConfig>, Pointer<Pointer<_AcEngine>>);
typedef _Open = int Function(Pointer<_AcConfig>, Pointer<Pointer<_AcEngine>>);

typedef _StatusC = Int32 Function(Pointer<_AcEngine>);
typedef _Status = int Function(Pointer<_AcEngine>);

typedef _CloseC = Void Function(Pointer<_AcEngine>);
typedef _Close = void Function(Pointer<_AcEngine>);

typedef _InfoC = Int32 Function(Pointer<_AcEngine>, Pointer<_AcInfo>);
typedef _Info = int Function(Pointer<_AcEngine>, Pointer<_AcInfo>);

typedef _Uint32C = Uint32 Function(Pointer<_AcEngine>);
typedef _Uint32 = int Function(Pointer<_AcEngine>);

typedef _Uint64C = Uint64 Function(Pointer<_AcEngine>);
typedef _Uint64 = int Function(Pointer<_AcEngine>);

typedef _TransferC = Uint32 Function(Pointer<_AcEngine>, Pointer<Float>, Uint32);
typedef _Transfer = int Function(Pointer<_AcEngine>, Pointer<Float>, int);

typedef _ScheduleC = Int32 Function(Pointer<_AcEngine>, Pointer<Float>, Uint32, Pointer<Uint64>);
typedef _Schedule = int Function(Pointer<_AcEngine>, Pointer<Float>, int, Pointer<Uint64>);

typedef _EndSampleC = Int32 Function(Pointer<_AcEngine>, Uint64, Pointer<Uint64>);
typedef _EndSample = int Function(Pointer<_AcEngine>, int, Pointer<Uint64>);

/// Funciones de la biblioteca, enlazadas una vez por carga.
class _Funciones {
  _Funciones(DynamicLibrary lib)
      : abrir = lib.lookupFunction<_OpenC, _Open>('ac_open'),
        arrancar = lib.lookupFunction<_StatusC, _Status>('ac_start'),
        parar = lib.lookupFunction<_StatusC, _Status>('ac_stop'),
        cerrar = lib.lookupFunction<_CloseC, _Close>('ac_close'),
        info = lib.lookupFunction<_InfoC, _Info>('ac_get_info'),
        contador = lib.lookupFunction<_Uint64C, _Uint64>('ac_sample_counter'),
        escribir = lib.lookupFunction<_TransferC, _Transfer>('ac_write_playback'),
        pendientes = lib.lookupFunction<_Uint32C, _Uint32>('ac_playback_pending'),
        programar = lib.lookupFunction<_ScheduleC, _Schedule>('ac_schedule_playback'),
        finBloque = lib.lookupFunction<_EndSampleC, _EndSample>('ac_playback_end_sample'),
        leer = lib.lookupFunction<_TransferC, _Transfer>('ac_read_capture'),
        silencio = lib.lookupFunction<_Uint64C, _Uint64>('ac_playback_underrun_frames'),
        descartes = lib.lookupFunction<_Uint64C, _Uint64>('ac_capture_overrun_frames');

  final _Open abrir;
  final _Status arrancar;
  final _Status parar;
  final _Close cerrar;
  final _Info info;
  final _Uint64 contador;
  final _Transfer escribir;
  final _Uint32 pendientes;
  final _Schedule programar;
  final _EndSample finBloque;
  final _Transfer leer;
  final _Uint64 silencio;
  final _Uint64 descartes;
}

DynamicLibrary _cargar(String? ruta) {
  if (ruta != null) return DynamicLibrary.open(ruta);
  if (Platform.isWindows) return DynamicLibrary.open('audio_core.dll');
  if (Platform.isMacOS) return DynamicLibrary.open('libaudio_core.dylib');
  if (Platform.isIOS) return DynamicLibrary.process();
  return DynamicLibrary.open('libaudio_core.so');
}

void _verificar(int codigo, String operacion) {
  if (codigo != _ok) throw ErrorNucleoAudio(codigo, operacion);
}

/// Copia [muestras] a memoria nativa y llama a [accion] con el puntero.
R _conEntrada<R>(Float32List muestras, R Function(Pointer<Float> ptr, int frames) accion) {
  final n = muestras.length;
  final ptr = calloc<Float>(math.max(n, 1));
  try {
    ptr.asTypedList(n).setAll(0, muestras);
    return accion(ptr, n);
  } finally {
    calloc.free(ptr);
  }
}

/// Motor de audio sobre `ac_*` de `audio_core.h`. Un motor por flujo.
class MotorAudioNativo implements MotorAudio {
  MotorAudioNativo._(this._f, this._motor);

  final _Funciones _f;
  final Pointer<_AcEngine> _motor;
  bool _cerrado = false;

  static MotorAudioNativo abrir(ConfiguracionAudio config, {String? ruta}) {
    final funciones = _Funciones(_cargar(ruta));
    final cfg = calloc<_AcConfig>();
    final salida = calloc<Pointer<_AcEngine>>();
    try {
      cfg.ref
        ..frecuenciaMuestreo = config.frecuenciaMuestreo
        ..tamanoPeriodo = config.tamanoPeriodo
        ..capacidadReproduccion = config.capacidadReproduccion
        ..capacidadCaptura = config.capacidadCaptura
        ..backendNulo = config.backendNulo ? 1 : 0;
      _verificar(funciones.abrir(cfg, salida), 'ac_open');
      return MotorAudioNativo._(funciones, salida.value);
    } finally {
      calloc.free(cfg);
      calloc.free(salida);
    }
  }

  Pointer<_AcEngine> get _vivo {
    if (_cerrado) throw StateError('El motor de audio ya está cerrado');
    return _motor;
  }

  @override
  InfoAudio get info {
    final salida = calloc<_AcInfo>();
    try {
      _verificar(_f.info(_vivo, salida), 'ac_get_info');
      final r = salida.ref;
      return InfoAudio(
        frecuenciaMuestreo: r.frecuenciaMuestreo,
        canales: r.canales,
        latenciaEntradaFramas: r.latenciaEntradaFramas,
        latenciaSalidaFramas: r.latenciaSalidaFramas,
      );
    } finally {
      calloc.free(salida);
    }
  }

  @override
  int get muestrasProcesadas => _f.contador(_vivo);

  @override
  int get framesSilencioReproduccion => _f.silencio(_vivo);

  @override
  int get framesDescartadosCaptura => _f.descartes(_vivo);

  @override
  int get pendientesReproduccion => _f.pendientes(_vivo);

  @override
  void arrancar() => _verificar(_f.arrancar(_vivo), 'ac_start');

  @override
  void parar() => _verificar(_f.parar(_vivo), 'ac_stop');

  @override
  void cerrar() {
    if (_cerrado) return;
    _cerrado = true;
    _f.cerrar(_motor);
  }

  @override
  int escribirReproduccion(Float32List muestras) =>
      _conEntrada(muestras, (ptr, n) => _f.escribir(_vivo, ptr, n));

  @override
  int? programarReproduccion(Float32List muestras) {
    final ticket = calloc<Uint64>();
    try {
      final codigo = _conEntrada(muestras, (ptr, n) => _f.programar(_vivo, ptr, n, ticket));
      if (codigo == _errEstado) return null;
      _verificar(codigo, 'ac_schedule_playback');
      return ticket.value;
    } finally {
      calloc.free(ticket);
    }
  }

  @override
  int? finDeBloque(int ticket) {
    final salida = calloc<Uint64>();
    try {
      final codigo = _f.finBloque(_vivo, ticket, salida);
      if (codigo == _errEstado) return null;
      _verificar(codigo, 'ac_playback_end_sample');
      return salida.value;
    } finally {
      calloc.free(salida);
    }
  }

  @override
  Float32List leerCaptura(int maximoFramas) {
    final n = math.max(maximoFramas, 1);
    final ptr = calloc<Float>(n);
    try {
      final leidos = _f.leer(_vivo, ptr, maximoFramas);
      return Float32List.fromList(ptr.asTypedList(n).sublist(0, leidos));
    } finally {
      calloc.free(ptr);
    }
  }
}
