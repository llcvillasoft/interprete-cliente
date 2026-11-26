import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/dominio/asr.dart';
import 'package:interprete_cliente/dominio/asr_motor.dart';

class _BackendFalso implements BackendWhisper {
  _BackendFalso({this.registros = const [], this.error});

  final List<RegistroWhisper> registros;
  final Object? error;
  int llamadas = 0;

  @override
  Future<List<RegistroWhisper>> transcribir(Float32List muestras, String idioma) async {
    llamadas++;
    if (error != null) throw error!;
    return registros;
  }
}

void main() {
  group('motor de reconocimiento sobre el backend', () {
    test('rechaza un audio vacío sin llamar al backend', () async {
      final backend = _BackendFalso();
      final motor = MotorAsrWhisper(backend);
      await expectLater(
        motor.transcribir(Float32List(0), idioma: 'es'),
        throwsArgumentError,
      );
      expect(backend.llamadas, 0);
    });

    test('rechaza un idioma vacío sin llamar al backend', () async {
      final backend = _BackendFalso();
      final motor = MotorAsrWhisper(backend);
      await expectLater(
        motor.transcribir(Float32List(16000), idioma: ''),
        throwsArgumentError,
      );
      expect(backend.llamadas, 0);
    });

    test('devuelve el idioma pedido y los segmentos del backend', () async {
      final backend = _BackendFalso(registros: [
        (t0: 0, t1: 150, texto: ' buenos '),
        (t0: 150, t1: 300, texto: 'días'),
      ]);
      final motor = MotorAsrWhisper(backend);
      final resultado = await motor.transcribir(Float32List(16000), idioma: 'es');
      expect(resultado.idioma, 'es');
      expect(resultado.segmentos, hasLength(2));
      expect(resultado.textoCompleto, 'buenos días');
    });

    test('propaga el error del backend', () async {
      final backend = _BackendFalso(error: StateError('modelo no cargado'));
      final motor = MotorAsrWhisper(backend);
      await expectLater(
        motor.transcribir(Float32List(16000), idioma: 'es'),
        throwsStateError,
      );
    });
  });
}
