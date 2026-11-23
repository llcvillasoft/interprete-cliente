import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/datos/api_cliente.dart';
import 'package:interprete_cliente/dominio/bandeja_salida.dart';
import 'package:interprete_cliente/dominio/ventana.dart';
import 'package:interprete_cliente/presentacion/raiz_pantalla.dart';

/// Transporte que nunca recibe eventos: la bandeja de esta prueba está siempre vacía.
class TransporteSinEnvios implements TransporteEventos {
  @override
  Future<ResultadoLote> enviarEventos(List<Evento> eventos) async =>
      const ResultadoLote(recibidos: 0, nuevos: 0, duplicados: 0);
}

class ApiFalsa implements ApiCliente {
  ApiFalsa(this.niveles);

  final Map<Direccion, List<double>> niveles;

  @override
  Future<List<double>> nivelesDe(Direccion direccion) async => niveles[direccion] ?? const [];

  @override
  Future<SesionCreada> crearSesion() async =>
      const SesionCreada(id: 'sesion-prueba-001', estado: 'created');

  @override
  Future<Map<String, bool>> consentimientos() async => const {};

  @override
  Future<ExportacionCreada> exportar() async =>
      const ExportacionCreada(usuario: 'usuario-prueba-001', flujos: 0);

  @override
  Future<ResultadoBorrado> borrarCuenta() async => const ResultadoBorrado(
        usuario: 'usuario-prueba-001',
        claveDestruida: false,
        sesiones: 0,
      );
}

Finder conIdentificador(String identificador) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.identifier == identificador,
    );

Future<void> abrirConAncho(WidgetTester tester, double ancho, ApiCliente api) async {
  tester.view.physicalSize = Size(ancho, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final bandeja = BandejaSalida(transporte: TransporteSinEnvios());
  await tester.pumpWidget(MaterialApp(home: RaizPantalla(api: api, bandeja: bandeja)));
  await tester.pumpAndSettle();
}

void main() {
  final api = ApiFalsa({
    Direccion.enEs: [1.2, 1.4],
    Direccion.esEn: [1.2, 1.2],
  });

  testWidgets('muestra la ventana sostenida de cada dirección', (tester) async {
    await abrirConAncho(tester, 390, api);

    expect(conIdentificador('hoy.ventana.en-es'), findsOneWidget);
    expect(conIdentificador('hoy.ventana.es-en'), findsOneWidget);
    expect(find.textContaining('f 1,40'), findsOneWidget);
    expect(find.textContaining('f 1,20'), findsOneWidget);
  });

  testWidgets('con ancho compacto la navegación es una barra inferior', (tester) async {
    await abrirConAncho(tester, 390, api);

    expect(conIdentificador('hoy.navegacion.barra'), findsOneWidget);
    expect(conIdentificador('hoy.navegacion.riel'), findsNothing);
  });

  testWidgets('con ancho amplio la navegación es un riel con etiquetas', (tester) async {
    await abrirConAncho(tester, 1440, api);

    expect(conIdentificador('hoy.navegacion.riel'), findsOneWidget);
    expect(conIdentificador('hoy.navegacion.barra'), findsNothing);
    expect(find.text('Cuaderno'), findsOneWidget);
  });

  testWidgets('practicar abre la sesión y el anillo no muestra cifras', (tester) async {
    await abrirConAncho(tester, 390, api);

    await tester.tap(conIdentificador('hoy.practicar.boton'));
    await tester.pumpAndSettle();

    expect(conIdentificador('sesion.anillo'), findsOneWidget);
    expect(conIdentificador('sesion.estado'), findsOneWidget);
    expect(find.text('Lista para grabar'), findsOneWidget);
    final anillo = tester.widget<Semantics>(conIdentificador('sesion.anillo'));
    expect(anillo.properties.label ?? '', isNot(matches(RegExp(r'\d'))));
  });

  testWidgets('desde Hoy se abre el estado del envío', (tester) async {
    await abrirConAncho(tester, 390, api);

    await tester.tap(conIdentificador('hoy.estado.envio.boton'));
    await tester.pumpAndSettle();

    expect(conIdentificador('estado.envio.pendientes'), findsOneWidget);
  });
}
