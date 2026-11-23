import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/dominio/bandeja_salida.dart';
import 'package:interprete_cliente/presentacion/estado_envio_pantalla.dart';
import 'package:interprete_cliente/recursos/textos.dart';

Evento evento(int n) => {
      'event_id': '00000000-0000-0000-0000-${n.toString().padLeft(12, '0')}',
      'type': 'SessionStarted',
      'origin_seq': n,
    };

/// Transporte falso con guion: cada paso es un lote aceptado, un `Exception` o un error de red.
class TransporteFalso implements TransporteEventos {
  TransporteFalso(this.guion);

  final List<Object> guion;

  @override
  Future<ResultadoLote> enviarEventos(List<Evento> eventos) async {
    final paso = guion.isEmpty ? null : guion.removeAt(0);
    if (paso is Exception) throw paso;
    return ResultadoLote(recibidos: eventos.length, nuevos: eventos.length, duplicados: 0);
  }
}

Future<void> sinEsperar(Duration duracion) async {}

Finder conIdentificador(String identificador) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.identifier == identificador,
    );

Future<void> abrir(WidgetTester tester, BandejaSalida bandeja) async {
  await tester.pumpWidget(MaterialApp(home: EstadoEnvioPantalla(bandeja: bandeja)));
  await tester.pumpAndSettle();
}

Future<void> sincronizar(WidgetTester tester, BandejaSalida bandeja) async {
  await tester.runAsync(bandeja.sincronizar);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra los eventos pendientes que hay en la bandeja', (tester) async {
    final bandeja = BandejaSalida(transporte: TransporteFalso([]), esperar: sinEsperar);
    bandeja.encolar([evento(1), evento(2), evento(3)]);

    await abrir(tester, bandeja);

    expect(conIdentificador('estado.envio.pendientes'), findsOneWidget);
    expect(find.text(Textos.enviosPendientes(3)), findsOneWidget);
  });

  testWidgets('antes de sincronizar dice que todavía no se ha sincronizado', (tester) async {
    final bandeja = BandejaSalida(transporte: TransporteFalso([]), esperar: sinEsperar);

    await abrir(tester, bandeja);

    expect(conIdentificador('estado.envio.ultima'), findsOneWidget);
    expect(find.text(Textos.sinSincronizar), findsOneWidget);
  });

  testWidgets('tras una sincronización completa, los pendientes bajan a cero y dice que fue completa',
      (tester) async {
    final bandeja = BandejaSalida(transporte: TransporteFalso([]), esperar: sinEsperar);
    bandeja.encolar([evento(1), evento(2)]);
    await abrir(tester, bandeja);

    await sincronizar(tester, bandeja);

    expect(find.text(Textos.enviosPendientes(0)), findsOneWidget);
    expect(find.text(Textos.ultimaSincronizacionCompleta), findsOneWidget);
  });

  testWidgets('sin conexión, dice que la última sincronización quedó incompleta', (tester) async {
    final bandeja = BandejaSalida(
      transporte: TransporteFalso([
        const ErrorTransitorio('sin red'),
        const ErrorTransitorio('sin red'),
      ]),
      reintentosMaximos: 1,
      esperar: sinEsperar,
    );
    bandeja.encolar([evento(1), evento(2)]);
    await abrir(tester, bandeja);

    await sincronizar(tester, bandeja);

    expect(find.text(Textos.enviosPendientes(2)), findsOneWidget);
    expect(find.text(Textos.ultimaSincronizacionIncompleta), findsOneWidget);
  });

  testWidgets('cuenta los eventos que el servidor rechazó de forma definitiva', (tester) async {
    final bandeja = BandejaSalida(
      transporte: TransporteFalso([const EventosRechazados(422, 'lote malformado')]),
      esperar: sinEsperar,
    );
    bandeja.encolar([evento(1), evento(2)]);
    await abrir(tester, bandeja);

    await sincronizar(tester, bandeja);

    expect(conIdentificador('estado.envio.rechazados'), findsOneWidget);
    expect(find.text(Textos.enviosRechazados(2)), findsOneWidget);
    expect(find.text(Textos.enviosPendientes(0)), findsOneWidget);
  });
}
