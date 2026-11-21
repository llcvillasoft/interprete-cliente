import '../bandeja_salida.dart' show Evento;
import 'huella.dart';

/// Lo que dejó recorrer un flujo: cuántos eventos, de qué orígenes y qué no cierra.
class InformeCadena {
  const InformeCadena({
    required this.flujo,
    required this.eventos,
    required this.origenes,
    required this.problemas,
  });

  final String flujo;
  final int eventos;
  final Map<String, int> origenes;
  final List<String> problemas;

  bool get ok => problemas.isEmpty;
}

/// Recorre los eventos de un flujo, en el orden en que llegaron, y recalcula las huellas y los eslabones.
///
/// Es la misma comprobación que hace el backend (`interp.events.chain.verify_stream`). Lo que no cierra se anota y no
/// detiene el recorrido: un evento de otro flujo o repetido se salta, y los demás se siguen comprobando.
InformeCadena verificarCadena(Iterable<Evento> eventos, {String? flujo}) {
  var flujoActual = flujo ?? '';
  var total = 0;
  final origenes = <String, int>{};
  final problemas = <String>[];
  final cabezas = <String, ({int seq, String hash})>{};
  final vistos = <String>{};

  for (final evento in eventos) {
    total++;
    final flujoEvento = evento['stream'] as String? ?? '';
    if (flujoActual.isEmpty) flujoActual = flujoEvento;
    final id = evento['event_id'] as String? ?? '?';

    if (flujoEvento != flujoActual) {
      problemas.add('$id: es del flujo $flujoEvento, no de $flujoActual');
      continue;
    }
    if (!vistos.add(id)) {
      problemas.add('$id: evento repetido');
      continue;
    }

    final origen = evento['origin'] as String? ?? '?';
    origenes[origen] = (origenes[origen] ?? 0) + 1;

    final guardada = evento['hash'] as String?;
    final calculada = huellaDeCuerpo(evento);
    if (calculada != guardada) {
      problemas.add('$id: la huella guardada no es la de su contenido (se calculó ${calculada.substring(0, 12)}…)');
    }

    final cabeza = cabezas[origen] ?? (seq: 0, hash: genesis);
    final seqCruda = evento['origin_seq'];
    final seq = seqCruda is int ? seqCruda : null;
    if (seq != cabeza.seq + 1) {
      problemas.add('$id: la secuencia de $origen salta de ${cabeza.seq} a $seqCruda');
    }
    if (evento['prev_hash'] != cabeza.hash) {
      problemas.add('$id: el eslabón no apunta al evento anterior de $origen');
    }
    cabezas[origen] = (seq: seq ?? cabeza.seq, hash: guardada ?? '');
  }

  return InformeCadena(
    flujo: flujoActual,
    eventos: total,
    origenes: origenes,
    problemas: problemas,
  );
}
