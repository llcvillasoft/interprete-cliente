import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/datos/api_cliente.dart';
import 'package:interprete_cliente/dominio/ventana.dart';
import 'package:interprete_cliente/presentacion/ajustes_pantalla.dart';
import 'package:interprete_cliente/recursos/textos.dart';

/// API de prueba que anota qué operaciones de privacidad se pidieron.
class ApiAjustesFalsa implements ApiCliente {
  ApiAjustesFalsa({this.consentidos = const {}});

  final Map<String, bool> consentidos;
  final List<String> llamadas = [];

  @override
  Future<List<double>> nivelesDe(Direccion direccion) async => const [];

  @override
  Future<SesionCreada> crearSesion() async =>
      const SesionCreada(id: 'sesion-prueba-001', estado: 'created');

  @override
  Future<Map<String, bool>> consentimientos() async {
    llamadas.add('consentimientos');
    return consentidos;
  }

  @override
  Future<ExportacionCreada> exportar() async {
    llamadas.add('exportar');
    return const ExportacionCreada(usuario: 'usuario-prueba-001', flujos: 2);
  }

  @override
  Future<ResultadoBorrado> borrarCuenta() async {
    llamadas.add('borrar');
    return const ResultadoBorrado(
      usuario: 'usuario-prueba-001',
      claveDestruida: true,
      sesiones: 3,
    );
  }
}

Future<void> abrir(WidgetTester tester, ApiAjustesFalsa api) async {
  await tester.pumpWidget(MaterialApp(home: AjustesPantalla(api: api)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra los consentimientos vigentes en solo lectura', (tester) async {
    await abrir(tester, ApiAjustesFalsa(consentidos: const {'audio': false}));

    expect(find.text('audio'), findsOneWidget);
    expect(find.text(Textos.noConcedido), findsOneWidget);
  });

  testWidgets('exportar pide el paquete y muestra cuántos flujos trae', (tester) async {
    final api = ApiAjustesFalsa();
    await abrir(tester, api);

    await tester.tap(find.text(Textos.exportarDatos));
    await tester.pumpAndSettle();

    expect(api.llamadas, contains('exportar'));
    expect(find.text(Textos.exportacionLista(2)), findsOneWidget);
  });

  testWidgets('borrar la cuenta exige confirmar antes de llamar a la API', (tester) async {
    final api = ApiAjustesFalsa();
    await abrir(tester, api);

    await tester.tap(find.text(Textos.borrarCuenta));
    await tester.pumpAndSettle();
    expect(find.text(Textos.borrarCuentaPregunta), findsOneWidget);

    await tester.tap(find.text(Textos.cancelar));
    await tester.pumpAndSettle();
    expect(api.llamadas, isNot(contains('borrar')));

    await tester.tap(find.text(Textos.borrarCuenta));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Textos.confirmarBorrado));
    await tester.pumpAndSettle();

    expect(api.llamadas, contains('borrar'));
    expect(find.text(Textos.cuentaBorrada(3)), findsOneWidget);
  });
}
