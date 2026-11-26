import 'dart:typed_data';

import 'asr.dart';

/// Backend de whisper.cpp: transcribe muestras y devuelve los registros crudos.
/// La implementación por FFI sobre la biblioteca nativa la aporta la capa de datos.
abstract interface class BackendWhisper {
  Future<List<RegistroWhisper>> transcribir(Float32List muestras, String idioma);
}

/// Motor de reconocimiento que valida la entrada y convierte la salida del backend.
class MotorAsrWhisper implements MotorAsr {
  MotorAsrWhisper(this._backend);

  final BackendWhisper _backend;

  @override
  Future<ResultadoAsr> transcribir(Float32List muestras, {required String idioma}) async {
    validarAudioAsr(muestras, frecuenciaAsr);
    if (idioma.isEmpty) {
      throw ArgumentError.value(idioma, 'idioma', 'Hace falta un idioma');
    }
    final registros = await _backend.transcribir(muestras, idioma);
    return ResultadoAsr(idioma: idioma, segmentos: segmentosDesdeWhisper(registros));
  }
}
