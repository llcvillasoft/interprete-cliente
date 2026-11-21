import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/datos/cifrado_aes_gcm.dart';
import 'package:interprete_cliente/dominio/expediente/cifrado.dart';

List<int> claveDePrueba(int semilla) => List<int>.generate(32, (i) => (i * 7 + semilla) & 0xff);

void main() {
  group('sellado del contenido personal (AES-256-GCM)', () {
    test('lo sellado se abre con la misma clave y el mismo AAD', () async {
      final cifrador = CifradorAesGcm(claveDePrueba(1), aleatorio: Random(1));

      final sellado = await cifrador.sellar('transcripción: ñandú', aad: 'sesion/evento-1');

      expect(sellado, startsWith('v1.'));
      expect(sellado, isNot(contains('ñandú')));
      expect(await cifrador.abrir(sellado, aad: 'sesion/evento-1'), 'transcripción: ñandú');
    });

    test('un AAD distinto no abre el contenido', () async {
      final cifrador = CifradorAesGcm(claveDePrueba(1), aleatorio: Random(1));
      final sellado = await cifrador.sellar('secreto', aad: 'sesion/evento-1');

      await expectLater(
        cifrador.abrir(sellado, aad: 'sesion/evento-2'),
        throwsA(isA<ErrorDeSellado>()),
      );
    });

    test('otra clave no abre el contenido', () async {
      final sellado = await CifradorAesGcm(claveDePrueba(1), aleatorio: Random(1))
          .sellar('secreto', aad: 'a');
      final otro = CifradorAesGcm(claveDePrueba(2), aleatorio: Random(1));

      await expectLater(otro.abrir(sellado, aad: 'a'), throwsA(isA<ErrorDeSellado>()));
    });

    test('dos sellados del mismo texto no son iguales, porque el nonce es aleatorio', () async {
      final cifrador = CifradorAesGcm(claveDePrueba(1), aleatorio: Random(1));

      final primero = await cifrador.sellar('igual', aad: 'a');
      final segundo = await cifrador.sellar('igual', aad: 'a');

      expect(primero, isNot(segundo));
    });

    test('un sellado alterado no se abre', () async {
      final cifrador = CifradorAesGcm(claveDePrueba(1), aleatorio: Random(1));
      final sellado = await cifrador.sellar('secreto', aad: 'a');
      final bytes = base64Url.decode(sellado.substring(3));
      bytes[bytes.length - 1] ^= 1;
      final alterado = 'v1.${base64Url.encode(bytes)}';

      await expectLater(cifrador.abrir(alterado, aad: 'a'), throwsA(isA<ErrorDeSellado>()));
    });

    test('un texto con otro formato se rechaza sin abrirse', () async {
      final cifrador = CifradorAesGcm(claveDePrueba(1), aleatorio: Random(1));

      await expectLater(cifrador.abrir('v9.abc', aad: 'a'), throwsA(isA<ErrorDeSellado>()));
      await expectLater(cifrador.abrir('v1.***', aad: 'a'), throwsA(isA<ErrorDeSellado>()));
    });
  });
}
