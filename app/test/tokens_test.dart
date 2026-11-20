import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/tokens.dart';

void main() {
  test('por debajo de 600 px el ancho es compacto', () {
    expect(anchoDe(390), AnchoPantalla.compacto);
    expect(anchoDe(599), AnchoPantalla.compacto);
  });

  test('de 600 a 1024 px el ancho es medio, incluidos los límites', () {
    expect(anchoDe(600), AnchoPantalla.medio);
    expect(anchoDe(834), AnchoPantalla.medio);
    expect(anchoDe(1024), AnchoPantalla.medio);
  });

  test('por encima de 1024 px el ancho es amplio', () {
    expect(anchoDe(1025), AnchoPantalla.amplio);
    expect(anchoDe(1440), AnchoPantalla.amplio);
  });
}
