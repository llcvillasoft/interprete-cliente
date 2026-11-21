import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/datos/nucleo_audio.dart';

/// Ruta de `libaudio_core`. CI la compila antes de las pruebas de Flutter.
final String? _ruta = Platform.environment['AUDIO_CORE_LIB'];

/// Las pruebas que cargan la biblioteca se omiten, con su motivo, si no hay ruta.
final Object? _omitir = _ruta == null ? 'define AUDIO_CORE_LIB con la ruta de libaudio_core' : null;

/// Motor de backend nulo: no necesita tarjeta de sonido.
MotorAudio _abrir({int capacidadReproduccion = 0}) => abrirMotorAudio(
      config: ConfiguracionAudio(
        frecuenciaMuestreo: 48000,
        capacidadReproduccion: capacidadReproduccion,
        backendNulo: true,
      ),
      ruta: _ruta,
    );

/// Sondea [condicion] cada 10 ms hasta que se cumple o se agota [limite].
Future<bool> _esperar(
  bool Function() condicion, {
  Duration limite = const Duration(seconds: 3),
}) async {
  final fin = DateTime.now().add(limite);
  while (!condicion()) {
    if (DateTime.now().isAfter(fin)) return false;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return true;
}

Matcher _errorNativo(String nombre) =>
    throwsA(isA<ErrorNucleoAudio>().having((e) => e.nombre, 'nombre', nombre));

void main() {
  group('errores y configuración, sin biblioteca', () {
    test('cada código de ac_status tiene su nombre', () {
      expect(ErrorNucleoAudio(-1, 'x').nombre, 'AC_ERR_ARG');
      expect(ErrorNucleoAudio(-2, 'x').nombre, 'AC_ERR_INIT');
      expect(ErrorNucleoAudio(-3, 'x').nombre, 'AC_ERR_DEVICE');
      expect(ErrorNucleoAudio(-4, 'x').nombre, 'AC_ERR_STATE');
    });

    test('un código que no existe se marca como desconocido', () {
      expect(ErrorNucleoAudio(-99, 'x').nombre, 'AC_ERR_DESCONOCIDO');
    });

    test('la configuración por omisión deja los valores al núcleo', () {
      const config = ConfiguracionAudio();
      expect(config.frecuenciaMuestreo, 0);
      expect(config.tamanoPeriodo, 0);
      expect(config.capacidadReproduccion, 0);
      expect(config.capacidadCaptura, 0);
      expect(config.backendNulo, isFalse);
    });

    test('una frecuencia negativa no es una configuración válida', () {
      expect(() => ConfiguracionAudio(frecuenciaMuestreo: -1), throwsA(isA<AssertionError>()));
    });
  });

  group('motor nativo con backend nulo', () {
    test('abre con el formato pedido y en mono', () {
      final motor = _abrir();
      addTearDown(motor.cerrar);

      expect(motor.info.frecuenciaMuestreo, 48000);
      expect(motor.info.canales, 1);
    }, skip: _omitir);

    test('parar sin arrancar es un error de estado', () {
      final motor = _abrir();
      addTearDown(motor.cerrar);

      expect(() => motor.parar(), _errorNativo('AC_ERR_STATE'));
    }, skip: _omitir);

    test('arrancar dos veces es un error de estado', () {
      final motor = _abrir();
      addTearDown(motor.cerrar);
      motor.arrancar();

      expect(() => motor.arrancar(), _errorNativo('AC_ERR_STATE'));
    }, skip: _omitir);

    test('el contador de muestras avanza solo mientras el motor corre', () async {
      final motor = _abrir();
      addTearDown(motor.cerrar);
      expect(motor.muestrasProcesadas, 0);

      motor.arrancar();
      expect(await _esperar(() => motor.muestrasProcesadas > 0), isTrue);

      motor.parar();
      final alParar = motor.muestrasProcesadas;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(motor.muestrasProcesadas, alParar);
    }, skip: _omitir);

    test('escribir la reproducción acepta solo lo que cabe', () {
      final motor = _abrir(capacidadReproduccion: 960);
      addTearDown(motor.cerrar);

      expect(motor.escribirReproduccion(Float32List(2000)), 960);
      expect(motor.pendientesReproduccion, 960);
    }, skip: _omitir);

    test('un bloque programado no entra si no cabe entero', () {
      final motor = _abrir(capacidadReproduccion: 960);
      addTearDown(motor.cerrar);

      expect(motor.programarReproduccion(Float32List(960)), isNotNull);
      expect(motor.programarReproduccion(Float32List(1)), isNull);
    }, skip: _omitir);

    test('el T0 de un bloque aparece cuando termina de sonar', () async {
      final motor = _abrir();
      addTearDown(motor.cerrar);
      motor.arrancar();

      final ticket = motor.programarReproduccion(Float32List(480))!;
      expect(await _esperar(() => motor.finDeBloque(ticket) != null), isTrue);

      final fin = motor.finDeBloque(ticket)!;
      expect(fin, greaterThanOrEqualTo(480));
      expect(fin, lessThanOrEqualTo(motor.muestrasProcesadas));
    }, skip: _omitir);

    test('un ticket que no existe es un error de argumento', () {
      final motor = _abrir();
      addTearDown(motor.cerrar);

      expect(() => motor.finDeBloque(999), _errorNativo('AC_ERR_ARG'));
    }, skip: _omitir);

    test('leer la captura sin marcha no devuelve audio', () {
      final motor = _abrir();
      addTearDown(motor.cerrar);

      expect(motor.leerCaptura(480), isEmpty);
    }, skip: _omitir);

    test('cerrar un motor en marcha lo para sin fallar', () {
      final motor = _abrir();
      motor.arrancar();

      expect(() {
        motor.cerrar();
        motor.cerrar();
      }, returnsNormally);
    }, skip: _omitir);

    test('usar el motor después de cerrarlo es un error de estado Dart', () {
      final motor = _abrir();
      motor.cerrar();

      expect(() => motor.muestrasProcesadas, throwsStateError);
    }, skip: _omitir);
  });
}
