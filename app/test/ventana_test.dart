import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/dominio/ventana.dart';

void main() {
  test('sin turnos no hay ventana', () {
    expect(ventanaDesde(Direccion.enEs, const []), isNull);
  });

  test('el factor actual es el del último turno', () {
    final ventana = ventanaDesde(Direccion.enEs, const [1.2, 1.4])!;
    expect(ventana.factor, 1.4);
  });

  test('si el factor sube, la tendencia es al alza', () {
    final ventana = ventanaDesde(Direccion.enEs, const [1.2, 1.4])!;
    expect(ventana.tendencia, Tendencia.alAlza);
  });

  test('si el factor baja, la tendencia es a la baja', () {
    final ventana = ventanaDesde(Direccion.esEn, const [1.4, 1.2])!;
    expect(ventana.tendencia, Tendencia.alaBaja);
  });

  test('con el mismo factor en los dos últimos turnos la tendencia es estable', () {
    final ventana = ventanaDesde(Direccion.esEn, const [1.2, 1.2])!;
    expect(ventana.tendencia, Tendencia.estable);
  });

  test('con un solo turno la tendencia es estable', () {
    final ventana = ventanaDesde(Direccion.enEs, const [1.0])!;
    expect(ventana.tendencia, Tendencia.estable);
  });

  test('el factor se muestra con coma decimal y dos cifras', () {
    expect(formatoFactor(1.4), '1,40');
    expect(formatoFactor(1.2), '1,20');
  });

  test('cada dirección tiene su identificador de semántica del contrato', () {
    expect(Direccion.enEs.identificador, 'en-es');
    expect(Direccion.esEn.identificador, 'es-en');
  });
}
