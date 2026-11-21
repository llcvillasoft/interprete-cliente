import 'nucleo_audio_tipos.dart';

/// Sin `dart:io` no hay biblioteca nativa. El núcleo web es F2-04.
MotorAudio abrirMotorAudio({
  ConfiguracionAudio config = const ConfiguracionAudio(),
  String? ruta,
}) =>
    throw UnsupportedError('El núcleo de audio nativo no está disponible en esta plataforma');
