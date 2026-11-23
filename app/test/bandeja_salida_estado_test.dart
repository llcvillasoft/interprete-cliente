import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/dominio/bandeja_salida.dart';

/// Evento mínimo: la bandeja solo necesita su identidad y su orden.
Evento evento(int n) => {
      'event_id': '00000000-0000-0000-0000-${n.toString().padLeft(12, '0')}',
      'type': 'SessionStarted',
      'origin_seq': n,
    };

/// Transporte con guion: cada paso responde a un envío en orden. Un `Exception` se lanza; cualquier otro
/// valor acepta el lote entero.
class TransporteGuion implements TransporteEventos {
  TransporteGuion(this.guion);

  final List<Object> guion;

  @override
  Future<ResultadoLote> enviarEventos(List<Evento> eventos) async {
    final paso = guion.isEmpty ? null : guion.removeAt(0);
    if (paso is Exception) throw paso;
    return ResultadoLote(recibidos: eventos.length, nuevos: eventos.length, duplicados: 0);
  }
}

Future<void> sinEsperar(Duration duracion) async {}

void main() {
  test('no hay última sincronización hasta que la bandeja sincroniza', () {
    final bandeja = BandejaSalida(transporte: TransporteGuion([]), esperar: sinEsperar);

    expect(bandeja.ultimaSincronizacion, isNull);
  });

  test('tras una sincronización completa, la última queda completa', () async {
    final bandeja = BandejaSalida(transporte: TransporteGuion([]), esperar: sinEsperar);
    bandeja.encolar([evento(1), evento(2)]);

    await bandeja.sincronizar();

    expect(bandeja.ultimaSincronizacion?.completa, isTrue);
    expect(bandeja.ultimaSincronizacion?.nuevos, 2);
  });

  test('sin conexión, la última queda incompleta y los eventos siguen pendientes', () async {
    final bandeja = BandejaSalida(
      transporte: TransporteGuion([
        const ErrorTransitorio('sin red'),
        const ErrorTransitorio('sin red'),
        const ErrorTransitorio('sin red'),
      ]),
      reintentosMaximos: 2,
      esperar: sinEsperar,
    );
    bandeja.encolar([evento(1)]);

    await bandeja.sincronizar();

    expect(bandeja.ultimaSincronizacion?.completa, isFalse);
    expect(bandeja.ultimaSincronizacion?.pendientes, 1);
    expect(bandeja.pendientes, 1);
  });

  test('avisa a sus oyentes al encolar y al terminar cada lote', () async {
    final bandeja = BandejaSalida(transporte: TransporteGuion([]), esperar: sinEsperar);
    var avisos = 0;
    bandeja.cambios.listen((_) {
      avisos++;
    });

    bandeja.encolar([evento(1), evento(2)]);
    await Future<void>.delayed(Duration.zero);
    expect(avisos, 1);

    await bandeja.sincronizar();
    await Future<void>.delayed(Duration.zero);
    expect(avisos, greaterThan(1));
  });
}
