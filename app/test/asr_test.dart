import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/dominio/asr.dart';

void main() {
  group('audio para el reconocedor', () {
    test('acepta muestras a 16 kHz', () {
      expect(() => validarAudioAsr(Float32List(16000), 16000), returnsNormally);
    });

    test('rechaza una frecuencia distinta de 16 kHz', () {
      expect(() => validarAudioAsr(Float32List(16000), 48000), throwsArgumentError);
    });

    test('rechaza un audio vacío', () {
      expect(() => validarAudioAsr(Float32List(0), 16000), throwsArgumentError);
    });
  });

  group('segmentos y texto', () {
    test('un segmento no puede terminar antes de empezar', () {
      expect(
        () => SegmentoAsr.nuevo(
          inicio: const Duration(seconds: 2),
          fin: const Duration(seconds: 1),
          texto: 'hola',
        ),
        throwsArgumentError,
      );
    });

    test('el texto completo une los segmentos en orden y descarta los vacíos', () {
      final resultado = ResultadoAsr(
        idioma: 'es',
        segmentos: [
          SegmentoAsr.nuevo(
            inicio: Duration.zero,
            fin: const Duration(seconds: 1),
            texto: ' Buenos días ',
          ),
          SegmentoAsr.nuevo(
            inicio: const Duration(seconds: 1),
            fin: const Duration(seconds: 2),
            texto: '',
          ),
          SegmentoAsr.nuevo(
            inicio: const Duration(seconds: 2),
            fin: const Duration(seconds: 3),
            texto: 'a todos',
          ),
        ],
      );
      expect(resultado.textoCompleto, 'Buenos días a todos');
    });
  });

  group('modelo de reconocimiento', () {
    test('el hash del modelo debe ser SHA-256 en hexadecimal minúsculo', () {
      expect(
        () => ModeloAsr.nuevo(identificador: 'tiny', bytes: 1000, sha256: 'abc'),
        throwsArgumentError,
      );
    });

    test('un modelo sin bytes no es válido', () {
      expect(
        () => ModeloAsr.nuevo(identificador: 'tiny', bytes: 0, sha256: 'a' * 64),
        throwsArgumentError,
      );
    });

    test('un modelo válido conserva su identificador y su tamaño', () {
      final modelo = ModeloAsr.nuevo(identificador: 'tiny', bytes: 1000, sha256: 'a' * 64);
      expect(modelo.identificador, 'tiny');
      expect(modelo.bytes, 1000);
    });
  });
}
