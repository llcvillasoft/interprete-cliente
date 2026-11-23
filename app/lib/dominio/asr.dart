import 'dart:typed_data';

/// Frecuencia que exige el reconocedor de voz (whisper.cpp): 16 kHz, mono, en coma flotante.
const int frecuenciaAsr = 16000;

/// Comprueba que el audio llega en el formato que exige el reconocedor.
void validarAudioAsr(Float32List muestras, int frecuenciaMuestreo) {
  if (frecuenciaMuestreo != frecuenciaAsr) {
    throw ArgumentError.value(
      frecuenciaMuestreo,
      'frecuenciaMuestreo',
      'El reconocedor necesita $frecuenciaAsr Hz',
    );
  }
  if (muestras.isEmpty) {
    throw ArgumentError.value(muestras.length, 'muestras', 'No hay audio que reconocer');
  }
}

/// Tramo reconocido, con su posición dentro del audio.
class SegmentoAsr {
  const SegmentoAsr._(this.inicio, this.fin, this.texto);

  factory SegmentoAsr.nuevo({
    required Duration inicio,
    required Duration fin,
    required String texto,
  }) {
    if (fin < inicio) {
      throw ArgumentError.value(fin, 'fin', 'El segmento termina antes de empezar');
    }
    return SegmentoAsr._(inicio, fin, texto);
  }

  final Duration inicio;
  final Duration fin;
  final String texto;
}

/// Resultado del reconocimiento de un audio.
class ResultadoAsr {
  const ResultadoAsr({required this.idioma, required this.segmentos});

  final String idioma;
  final List<SegmentoAsr> segmentos;

  /// Texto de todos los segmentos, en orden, sin los vacíos.
  String get textoCompleto => segmentos
      .map((segmento) => segmento.texto.trim())
      .where((texto) => texto.isNotEmpty)
      .join(' ');
}

/// Modelo de reconocimiento que se descarga y se verifica por su hash.
class ModeloAsr {
  const ModeloAsr._(this.identificador, this.bytes, this.sha256);

  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');

  factory ModeloAsr.nuevo({
    required String identificador,
    required int bytes,
    required String sha256,
  }) {
    if (identificador.isEmpty) {
      throw ArgumentError.value(identificador, 'identificador', 'El modelo necesita un nombre');
    }
    if (bytes <= 0) {
      throw ArgumentError.value(bytes, 'bytes', 'El modelo necesita un tamaño');
    }
    if (!_sha256.hasMatch(sha256)) {
      throw ArgumentError.value(sha256, 'sha256', 'Se espera SHA-256 en hexadecimal minúsculo');
    }
    return ModeloAsr._(identificador, bytes, sha256);
  }

  final String identificador;
  final int bytes;
  final String sha256;
}

/// Motor de reconocimiento de voz. La implementación por FFI sobre whisper.cpp llega en F2-07.
abstract interface class MotorAsr {
  Future<ResultadoAsr> transcribir(Float32List muestras, {required String idioma});
}
