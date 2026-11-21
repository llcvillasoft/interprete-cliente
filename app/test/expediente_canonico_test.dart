import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/dominio/expediente/canonico.dart';
import 'package:interprete_cliente/dominio/expediente/huella.dart';

import 'vectores_expediente.dart';

/// Cuerpo de un evento de referencia. Sus valores son los del vector del backend.
Map<String, dynamic> cuerpoDeReferencia() => <String, dynamic>{
      'event_id': '0190a5d0-0000-7000-8000-000000000001',
      'type': 'SessionStarted',
      'schema_version': 1,
      'stream': 'sesion-vector',
      'origin': 'dispositivo',
      'origin_seq': 1,
      'hlc': {'wall_ms': 1763510400123, 'counter': 0},
      'occurred_at': '2026-11-18T23:20:00.123Z',
      'scope': 'transportable',
      'actor': 'user',
      'manifest': 'a' * 64,
      'payload': {
        'tramo': {'inicio_ms': 1500.25, 'fin_ms': 2750},
        'nota': 'ñandú ✓',
      },
      'prev_hash': '0' * 64,
    };

void main() {
  group('forma canónica (RFC 8785), igual que en el backend', () {
    test('escribe los números como los escribe JavaScript', () {
      const casos = <double, String>{
        0.0: '0',
        1.0: '1',
        4.5: '4.5',
        0.002: '0.002',
        1e-6: '0.000001',
        1e-7: '1e-7',
        1e21: '1e+21',
        1e20: '100000000000000000000',
        333333333.33333329: '333333333.3333333',
        1e30: '1e+30',
        -1.5e-9: '-1.5e-9',
        123456.789: '123456.789',
      };
      casos.forEach((valor, texto) {
        expect(canonico(valor), texto, reason: 'valor $valor');
      });
    });

    test('un cero negativo se escribe como cero', () {
      expect(canonico(-0.0), '0');
    });

    test('los enteros se escriben tal cual', () {
      expect(canonico(12), '12');
      expect(canonico(-3), '-3');
    });

    test('rechaza NaN e infinito, que no tienen forma canónica', () {
      expect(() => canonico(double.nan), throwsArgumentError);
      expect(() => canonico(double.infinity), throwsArgumentError);
    });

    test('ordena las claves y no deja espacios', () {
      expect(
        canonico({'b': [1, 2.0, null, true], 'a': 'ñ\n'}),
        '{"a":"ñ\\n","b":[1,2,null,true]}',
      );
    });

    test('ordena las claves por unidades de código UTF-16', () {
      expect(canonico({'ﬁ': 1, '\u{1F600}': 2}), '{"\u{1F600}":2,"ﬁ":1}');
    });

    test('escapa solo lo que JSON obliga', () {
      expect(
        canonico('a"b\\c\u0001\u001f\u007f/\n\t\r\b\f'),
        r'"a\"b\\c\u0001\u001f' '\u007f' r'/\n\t\r\b\f"',
      );
    });

    test('reproduce el objeto de referencia del backend', () {
      final objeto = {
        'z': 1.5e-7,
        'a': {
          'ñ': false,
          'b': [null, 0.1, 100.0, 1e21, -0.0, 4.5, 0.000001],
        },
        'ctl': 'a"b\\c\u0001\u001f\u007f/\n\t\r\b\f',
        'ﬁ': 1,
        '\u{1F600}': 2,
      };
      expect(canonico(objeto), vectorCanonicoObjeto);
    });
  });

  group('huella de un cuerpo', () {
    test('es el SHA-256 del canónico del objeto de referencia', () {
      expect(huellaDeTexto(canonico(_objetoDeReferencia())), vectorHuellaCanonicoObjeto);
    });

    test('coincide con la huella que calcula el backend para un evento', () {
      expect(huellaDeCuerpo(cuerpoDeReferencia()), vectorHuellaCuerpo);
    });

    test('no cuenta el campo hash', () {
      expect(
        huellaDeCuerpo({...cuerpoDeReferencia(), 'hash': 'x' * 64}),
        vectorHuellaCuerpo,
      );
    });

    test('no depende del orden en que se escriben las claves', () {
      final invertido = Map<String, dynamic>.fromEntries(
        cuerpoDeReferencia().entries.toList().reversed,
      );
      expect(huellaDeCuerpo(invertido), vectorHuellaCuerpo);
    });

    test('cambia con cualquier campo', () {
      final cambiado = cuerpoDeReferencia()..['payload'] = {'nota': 'otra'};
      expect(huellaDeCuerpo(cambiado), isNot(vectorHuellaCuerpo));
    });

    test('el génesis de una cadena son 64 ceros', () {
      expect(genesis, '0' * 64);
    });
  });
}

Map<String, Object?> _objetoDeReferencia() => {
      'z': 1.5e-7,
      'a': {
        'ñ': false,
        'b': [null, 0.1, 100.0, 1e21, -0.0, 4.5, 0.000001],
      },
      'ctl': 'a"b\\c\u0001\u001f\u007f/\n\t\r\b\f',
      'ﬁ': 1,
      '\u{1F600}': 2,
    };
