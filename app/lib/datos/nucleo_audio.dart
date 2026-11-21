/// Acceso al núcleo de audio. Con `dart:io` carga `libaudio_core`; en web
/// `abrirMotorAudio` falla hasta que F2-04 aporte el núcleo web.
export 'nucleo_audio_tipos.dart';
export 'nucleo_audio_sin_nativo.dart' if (dart.library.io) 'nucleo_audio_nativo.dart';
