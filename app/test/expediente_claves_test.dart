import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/datos/expediente_memoria.dart';
import 'package:interprete_cliente/dominio/expediente/claves.dart';

void main() {
  group('almacén de claves por usuario', () {
    test('la clave de un usuario mide 32 bytes y no cambia entre llamadas', () async {
      final almacen = AlmacenClavesMemoria(aleatorio: Random(1));

      final primera = await almacen.claveDeUsuario('ana');
      final segunda = await almacen.claveDeUsuario('ana');

      expect(primera, hasLength(32));
      expect(segunda, primera);
    });

    test('usuarios distintos tienen claves distintas', () async {
      final almacen = AlmacenClavesMemoria(aleatorio: Random(1));

      final ana = await almacen.claveDeUsuario('ana');
      final luis = await almacen.claveDeUsuario('luis');

      expect(luis, isNot(ana));
    });

    test('destruida la clave, el usuario no recupera la anterior ni recibe otra', () async {
      final almacen = AlmacenClavesMemoria(aleatorio: Random(1));
      await almacen.claveDeUsuario('ana');

      await almacen.destruirClave('ana');

      await expectLater(almacen.claveDeUsuario('ana'), throwsA(isA<ClaveDestruida>()));
    });

    test('destruir la clave de un usuario no toca la de los demás', () async {
      final almacen = AlmacenClavesMemoria(aleatorio: Random(1));
      final luis = await almacen.claveDeUsuario('luis');
      await almacen.claveDeUsuario('ana');

      await almacen.destruirClave('ana');

      expect(await almacen.claveDeUsuario('luis'), luis);
    });
  });
}
