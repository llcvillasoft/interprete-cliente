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
///
/// El tamaño es aproximado y sirve para mostrar la descarga; la verificación real es el hash.
class ModeloAsr {
  const ModeloAsr._(this.identificador, this.megabytes, this.sha256);

  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');

  factory ModeloAsr.nuevo({
    required String identificador,
    required double megabytes,
    required String sha256,
  }) {
    if (identificador.isEmpty) {
      throw ArgumentError.value(identificador, 'identificador', 'El modelo necesita un nombre');
    }
    if (megabytes <= 0) {
      throw ArgumentError.value(megabytes, 'megabytes', 'El modelo necesita un tamaño');
    }
    if (!_sha256.hasMatch(sha256)) {
      throw ArgumentError.value(sha256, 'sha256', 'Se espera SHA-256 en hexadecimal minúsculo');
    }
    return ModeloAsr._(identificador, megabytes, sha256);
  }

  final String identificador;
  final double megabytes;
  final String sha256;
}

/// Memoria y núcleos del equipo, para elegir el modelo de reconocimiento.
class CapacidadEquipo {
  const CapacidadEquipo({required this.memoriaMb, required this.nucleos});

  final int memoriaMb;
  final int nucleos;
}

/// Modelos de la versión 1, con el hash que publica Hugging Face para cada archivo.
///
/// El tamaño viene de la columna «Disk» de whisper.cpp y del tamaño del archivo en Hugging Face.
final ModeloAsr modeloTiny = ModeloAsr.nuevo(
  identificador: 'tiny',
  megabytes: 77.7,
  sha256: 'be07e048e1e599ad46341c8d2a135645097a538221678b7acdd1b1919c6e1b21',
);

final ModeloAsr modeloBase = ModeloAsr.nuevo(
  identificador: 'base',
  megabytes: 148,
  sha256: '60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe',
);

final ModeloAsr modeloSmall = ModeloAsr.nuevo(
  identificador: 'small',
  megabytes: 488,
  sha256: '1be3a9b2063867b937e64e2ec7483364a79917e157fa98c5d94b5c1fffea987b',
);

/// Umbrales provisionales. La memoria de cada modelo, según whisper.cpp, es de unos 273 MB
/// (tiny), 388 MB (base) y 852 MB (small). Se validan con las mediciones de F2-16.
const int _memoriaSmallMb = 3072;
const int _nucleosSmall = 4;
const int _memoriaBaseMb = 1536;

/// Elige el modelo más grande que el equipo puede sostener con margen.
ModeloAsr elegirModeloAsr(CapacidadEquipo capacidad) {
  if (capacidad.memoriaMb >= _memoriaSmallMb && capacidad.nucleos >= _nucleosSmall) {
    return modeloSmall;
  }
  if (capacidad.memoriaMb >= _memoriaBaseMb) return modeloBase;
  return modeloTiny;
}

/// Motor de reconocimiento de voz. La implementación por FFI sobre whisper.cpp llega en F2-07.
abstract interface class MotorAsr {
  Future<ResultadoAsr> transcribir(Float32List muestras, {required String idioma});
}
