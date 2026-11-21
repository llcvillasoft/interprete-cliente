import 'dart:typed_data';

/// Error devuelto por el núcleo de audio nativo (`ac_status` de `audio_core.h`).
class ErrorNucleoAudio implements Exception {
  const ErrorNucleoAudio(this.codigo, this.operacion);

  /// Valor de `ac_status` tal como lo devuelve la biblioteca.
  final int codigo;

  /// Función del núcleo que falló, para diagnóstico.
  final String operacion;

  /// Nombre del código en la cabecera.
  String get nombre => switch (codigo) {
        -1 => 'AC_ERR_ARG',
        -2 => 'AC_ERR_INIT',
        -3 => 'AC_ERR_DEVICE',
        -4 => 'AC_ERR_STATE',
        _ => 'AC_ERR_DESCONOCIDO',
      };

  @override
  String toString() => 'ErrorNucleoAudio($nombre en $operacion)';
}

/// Parámetros de apertura. Un 0 deja el valor al núcleo, como en `ac_config`.
class ConfiguracionAudio {
  const ConfiguracionAudio({
    this.frecuenciaMuestreo = 0,
    this.tamanoPeriodo = 0,
    this.capacidadReproduccion = 0,
    this.capacidadCaptura = 0,
    this.backendNulo = false,
  })  : assert(frecuenciaMuestreo >= 0),
        assert(tamanoPeriodo >= 0),
        assert(capacidadReproduccion >= 0),
        assert(capacidadCaptura >= 0);

  /// Frecuencia en hercios; 0 usa la nativa del dispositivo.
  final int frecuenciaMuestreo;

  /// Frames por periodo; 0 usa el de miniaudio.
  final int tamanoPeriodo;

  /// Frames del búfer de reproducción; 0 equivale a un segundo.
  final int capacidadReproduccion;

  /// Frames del búfer de captura; 0 equivale a un segundo.
  final int capacidadCaptura;

  /// Solo para pruebas: corre sin tarjeta de sonido.
  final bool backendNulo;
}

/// Formato real del flujo abierto.
class InfoAudio {
  const InfoAudio({
    required this.frecuenciaMuestreo,
    required this.canales,
    required this.latenciaEntradaFramas,
    required this.latenciaSalidaFramas,
  });

  final int frecuenciaMuestreo;
  final int canales;
  final int latenciaEntradaFramas;
  final int latenciaSalidaFramas;
}

/// Lo que la aplicación necesita del núcleo de audio. Sin detalles de FFI.
///
/// Un método que devuelve `null` significa "todavía no" y no es un fallo:
/// un bloque que no cabe entero, o un bloque que aún no ha sonado.
abstract interface class MotorAudio {
  InfoAudio get info;

  /// Frames procesados por el hilo de audio desde que arrancó.
  int get muestrasProcesadas;

  /// Frames de silencio emitidos por falta de reproducción.
  int get framesSilencioReproduccion;

  /// Frames de captura descartados porque nadie los leyó a tiempo.
  int get framesDescartadosCaptura;

  /// Frames todavía pendientes de reproducir.
  int get pendientesReproduccion;

  void arrancar();
  void parar();

  /// Libera el motor. Llamarlo varias veces no falla; usarlo después, sí.
  void cerrar();

  /// Encola hasta `muestras.length` frames y devuelve los aceptados.
  int escribirReproduccion(Float32List muestras);

  /// Programa un bloque completo. Devuelve su ticket, o `null` si no cabe entero ahora.
  int? programarReproduccion(Float32List muestras);

  /// T0 del bloque: la muestra en que termina su audio. `null` mientras suena.
  int? finDeBloque(int ticket);

  /// Copia la captura disponible, hasta `maximoFramas`.
  Float32List leerCaptura(int maximoFramas);
}
