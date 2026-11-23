import '../bandeja_salida.dart';
import 'expediente.dart';

/// El flujo al que pertenece un evento del dispositivo: el de la sesión, o el del usuario (`user:<usuario>`).
enum FlujoDispositivo { sesion, usuario }

/// Qué pasa con un evento del dispositivo después de anexarlo al expediente local.
enum DestinoEvento {
  /// Solo en el expediente local: el audio crudo no sale del dispositivo.
  soloLocal,

  /// Se anexa y se encola para el siguiente lote.
  bandeja,

  /// Se anexa, pero no se encola: su contenido personal espera a acordar el formato del sellado con el servidor.
  enEspera,
}

/// Los eventos que emite el dispositivo, con el nombre que les da el catálogo del backend.
enum TipoEventoDispositivo {
  sessionStarted('SessionStarted', FlujoDispositivo.sesion),
  sourcePlaybackEnded('SourcePlaybackEnded', FlujoDispositivo.sesion),
  stimulusDisplayed('StimulusDisplayed', FlujoDispositivo.sesion),
  windowClosed('WindowClosed', FlujoDispositivo.sesion),
  captureRecorded('CaptureRecorded', FlujoDispositivo.sesion, destino: DestinoEvento.soloLocal),
  captureFingerprinted('CaptureFingerprinted', FlujoDispositivo.sesion),
  vadSegmentsDetected('VadSegmentsDetected', FlujoDispositivo.sesion),
  transcriptProduced(
    'TranscriptProduced',
    FlujoDispositivo.sesion,
    destino: DestinoEvento.enEspera,
    camposPersonales: {'transcript'},
  ),
  decisionRated('DecisionRated', FlujoDispositivo.sesion),
  adviceRated('AdviceRated', FlujoDispositivo.sesion),
  consentGiven('ConsentGiven', FlujoDispositivo.usuario),
  consentWithdrawn('ConsentWithdrawn', FlujoDispositivo.usuario);

  const TipoEventoDispositivo(
    this.nombre,
    this.flujo, {
    this.destino = DestinoEvento.bandeja,
    this.camposPersonales = const <String>{},
  });

  /// El nombre del evento en el catálogo del backend.
  final String nombre;
  final FlujoDispositivo flujo;
  final DestinoEvento destino;

  /// Los campos que se sellan con la clave del usuario. El resto del contenido viaja en claro.
  final Set<String> camposPersonales;
}

/// Anexa al expediente local los eventos que emite el dispositivo y encola los que deben salir.
///
/// El flujo del usuario se deduce de [usuario]; el de la sesión lo recibe cada llamada. El [manifiesto] es la huella del
/// manifiesto del dispositivo: lo pasa quien construye el registro, porque el cliente todavía no lo recibe del servidor.
class RegistroEventosDispositivo {
  RegistroEventosDispositivo({
    required this.expediente,
    required this.bandeja,
    required this.usuario,
    required this.manifiesto,
  });

  final Expediente expediente;
  final BandejaSalida bandeja;
  final String usuario;
  final String manifiesto;

  /// Anexa el evento [tipo] y devuelve el evento tal como quedó guardado.
  ///
  /// [sesion] es el flujo de la sesión; los consentimientos, que son del usuario, no lo usan.
  /// Los campos de [carga] que están en [TipoEventoDispositivo.camposPersonales] se sellan; el resto va en claro.
  Future<Evento> registrar({
    required TipoEventoDispositivo tipo,
    required String sesion,
    Map<String, Object?> carga = const {},
    String? turnoId,
  }) async {
    final soloLocal = tipo.destino == DestinoEvento.soloLocal;
    final base = tipo.flujo == FlujoDispositivo.usuario ? 'user:$usuario' : sesion;
    final flujo = soloLocal ? '$base#local' : base;

    final publico = <String, Object?>{};
    final personal = <String, Object?>{};
    for (final entrada in carga.entries) {
      if (tipo.camposPersonales.contains(entrada.key)) {
        personal[entrada.key] = entrada.value;
      } else {
        publico[entrada.key] = entrada.value;
      }
    }

    final evento = await expediente.anexar(
      flujo: flujo,
      tipo: tipo.nombre,
      manifiesto: manifiesto,
      publico: publico,
      personal: personal.isEmpty ? null : personal,
      scope: soloLocal ? 'local' : 'transportable',
      turnoId: turnoId,
    );

    if (tipo.destino == DestinoEvento.bandeja) {
      bandeja.encolar([evento]);
    }
    return evento;
  }
}
