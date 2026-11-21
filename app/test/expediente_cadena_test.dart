import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/dominio/bandeja_salida.dart';
import 'package:interprete_cliente/dominio/expediente/cadena.dart';
import 'package:interprete_cliente/dominio/expediente/huella.dart';

import 'vectores_expediente.dart';

/// Copia de la cadena de referencia, para manipularla sin tocar el original.
List<Evento> copiaDelVector() {
  final crudo = jsonDecode(vectorCadena) as List<dynamic>;
  return [for (final e in crudo) Map<String, dynamic>.from(e as Map<String, dynamic>)];
}

/// Repone la huella de un evento manipulado, para aislar el problema que se quiere probar.
void recalcular(Evento evento) {
  evento['hash'] = huellaDeCuerpo(Map<String, dynamic>.of(evento)..remove('hash'));
}

void main() {
  group('verificación de la cadena de un flujo', () {
    test('una cadena que el backend da por íntegra verifica igual', () {
      final informe = verificarCadena(copiaDelVector(), flujo: 'sesion-cadena');

      expect(informe.ok, isTrue, reason: '${informe.problemas}');
      expect(informe.eventos, 3);
      expect(informe.origenes, {'dispositivo': 3});
    });

    test('un flujo sin eventos es íntegro', () {
      final informe = verificarCadena(const <Evento>[], flujo: 'vacio');

      expect(informe.ok, isTrue);
      expect(informe.eventos, 0);
    });

    test('detecta un contenido cambiado sin recalcular su huella', () {
      final eventos = copiaDelVector();
      eventos[1]['payload'] = {'ms': 99, 'n': 1};

      final informe = verificarCadena(eventos, flujo: 'sesion-cadena');

      expect(informe.ok, isFalse);
      expect(informe.problemas.single, contains('no es la de su contenido'));
    });

    test('detecta un evento quitado del medio, que deja un salto en la secuencia', () {
      final eventos = copiaDelVector()..removeAt(1);

      final informe = verificarCadena(eventos, flujo: 'sesion-cadena');

      expect(informe.ok, isFalse);
      expect(informe.problemas, contains(contains('salta de 1 a 3')));
    });

    test('detecta un eslabón que no apunta al evento anterior aunque la huella cuadre', () {
      final eventos = copiaDelVector();
      eventos[1]['prev_hash'] = 'f' * 64;
      recalcular(eventos[1]);

      final informe = verificarCadena(eventos, flujo: 'sesion-cadena');

      expect(informe.ok, isFalse);
      expect(informe.problemas, contains(contains('eslabón')));
      expect(informe.problemas, everyElement(isNot(contains('contenido'))));
    });

    test('el primer evento de un origen debe apuntar al génesis', () {
      final eventos = copiaDelVector();
      eventos[0]['prev_hash'] = 'a' * 64;
      recalcular(eventos[0]);

      final informe = verificarCadena(eventos, flujo: 'sesion-cadena');

      expect(informe.problemas.first, contains('eslabón'));
    });

    test('detecta un evento de otro flujo dentro de la cadena', () {
      final eventos = copiaDelVector();
      eventos[2]['stream'] = 'otro-flujo';

      final informe = verificarCadena(eventos, flujo: 'sesion-cadena');

      expect(informe.problemas.single, contains('es del flujo otro-flujo'));
    });

    test('detecta un evento repetido', () {
      final eventos = copiaDelVector()..add(copiaDelVector().first);

      final informe = verificarCadena(eventos, flujo: 'sesion-cadena');

      expect(informe.problemas.single, contains('evento repetido'));
    });

    test('toma el flujo del primer evento cuando no se indica', () {
      final informe = verificarCadena(copiaDelVector());

      expect(informe.flujo, 'sesion-cadena');
      expect(informe.ok, isTrue);
    });
  });
}
