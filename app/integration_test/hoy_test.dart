import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:interprete_cliente/config.dart';
import 'package:interprete_cliente/datos/api_cliente.dart';
import 'package:interprete_cliente/main.dart' as app;
import 'package:interprete_cliente/recursos/textos.dart';

/// Escenarios de pruebas/features/hoy.feature, ejecutados en el dispositivo real.
///
/// La API simulada tiene que estar en marcha (pruebas/bateria/lanzar_api.py) y la
/// app recibe su dirección con --dart-define=API_BASE_URL al ejecutar la prueba.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder conIdentificador(String identificador) => find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.identifier == identificador,
      );

  /// Espera a que aparezca el elemento. Con la API real, el dato llega fuera de los fotogramas,
  /// así que no sirve pumpAndSettle: se avanza el tiempo por intervalos hasta 10 segundos.
  Future<void> esperarA(WidgetTester tester, Finder buscado) async {
    for (var intento = 0; intento < 100; intento++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (buscado.evaluate().isNotEmpty) return;
    }
    fail('no apareció ${buscado.description} tras 10 segundos');
  }

  /// Monta la app con el ancho indicado. OverflowBox fija el tamaño aunque la ventana del
  /// sistema sea más estrecha (un iPhone no puede mostrar 1440 px), así que el formato es el
  /// mismo en todas las plataformas.
  Future<void> abrirConAncho(WidgetTester tester, double ancho) async {
    final api = ClienteHttp(
      baseUrl: urlApi,
      dispositivo: dispositivoApi,
      secreto: secretoApi,
    );
    await tester.pumpWidget(
      OverflowBox(
        minWidth: ancho,
        maxWidth: ancho,
        minHeight: 844,
        maxHeight: 844,
        child: app.AplicacionEntrenador(api: api),
      ),
    );
    await tester.pump();
  }

  testWidgets('la ventana sostenida se muestra para cada dirección', (tester) async {
    await abrirConAncho(tester, 390);

    await esperarA(tester, conIdentificador('hoy.ventana.en-es'));
    await esperarA(tester, conIdentificador('hoy.ventana.es-en'));
    expect(
      find.descendant(of: conIdentificador('hoy.ventana.en-es'), matching: find.textContaining('EN→ES')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: conIdentificador('hoy.ventana.es-en'), matching: find.textContaining('ES→EN')),
      findsOneWidget,
    );
  });

  testWidgets('en ancho compacto la navegación es una barra inferior', (tester) async {
    await abrirConAncho(tester, 390);

    await esperarA(tester, conIdentificador('hoy.navegacion.barra'));
    expect(conIdentificador('hoy.navegacion.riel'), findsNothing);
  });

  testWidgets('en ancho amplio la navegación es un riel con etiquetas', (tester) async {
    await abrirConAncho(tester, 1440);

    await esperarA(tester, conIdentificador('hoy.navegacion.riel'));
    expect(conIdentificador('hoy.navegacion.barra'), findsNothing);
    expect(find.text(Textos.cuaderno), findsOneWidget);
  });

  testWidgets('durante una sesión el anillo no muestra cifras', (tester) async {
    await abrirConAncho(tester, 390);

    await esperarA(tester, conIdentificador('hoy.practicar.boton'));
    await tester.tap(conIdentificador('hoy.practicar.boton'));
    await esperarA(tester, conIdentificador('sesion.estado'));
    await esperarA(tester, conIdentificador('sesion.anillo'));

    final anillo = tester.widget<Semantics>(conIdentificador('sesion.anillo'));
    expect(anillo.properties.label ?? '', isNot(matches(RegExp(r'\d'))));
  });
}
