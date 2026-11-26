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

  group('conversión de segmentos de whisper.cpp', () {
    test('convierte centésimas de segundo en duraciones y recorta el texto', () {
      final segmentos = segmentosDesdeWhisper([(t0: 0, t1: 250, texto: ' hola ')]);
      expect(segmentos, hasLength(1));
      expect(segmentos.single.inicio, Duration.zero);
      expect(segmentos.single.fin, const Duration(milliseconds: 2500));
      expect(segmentos.single.texto, 'hola');
    });

    test('mantiene el orden de los registros', () {
      final segmentos = segmentosDesdeWhisper([
        (t0: 0, t1: 100, texto: 'uno'),
        (t0: 100, t1: 200, texto: 'dos'),
      ]);
      expect(segmentos.map((s) => s.texto), ['uno', 'dos']);
    });

    test('una lista vacía da una lista vacía', () {
      expect(segmentosDesdeWhisper(const []), isEmpty);
    });

    test('rechaza un registro cuyo fin es anterior al inicio', () {
      expect(
        () => segmentosDesdeWhisper([(t0: 200, t1: 100, texto: 'mal')]),
        throwsArgumentError,
      );
    });
  });

  group('modelo de reconocimiento', () {
    test('el hash del modelo debe ser SHA-256 en hexadecimal minúsculo', () {
      expect(
        () => ModeloAsr.nuevo(identificador: 'tiny', megabytes: 78, sha256: 'abc'),
        throwsArgumentError,
      );
    });

    test('un modelo sin tamaño no es válido', () {
      expect(
        () => ModeloAsr.nuevo(identificador: 'tiny', megabytes: 0, sha256: 'a' * 64),
        throwsArgumentError,
      );
    });

    test('un modelo válido conserva su identificador y su tamaño', () {
      final modelo = ModeloAsr.nuevo(identificador: 'tiny', megabytes: 77.7, sha256: 'a' * 64);
      expect(modelo.identificador, 'tiny');
      expect(modelo.megabytes, 77.7);
    });
  });

  group('elección del modelo según el equipo', () {
    test('un equipo con 4 GB y 8 núcleos recibe el modelo small', () {
      final modelo = elegirModeloAsr(const CapacidadEquipo(memoriaMb: 4096, nucleos: 8));
      expect(modelo.identificador, 'small');
    });

    test('en el límite de 3 GB y 4 núcleos también recibe small', () {
      final modelo = elegirModeloAsr(const CapacidadEquipo(memoriaMb: 3072, nucleos: 4));
      expect(modelo.identificador, 'small');
    });

    test('con 3 GB pero solo 2 núcleos recibe base', () {
      final modelo = elegirModeloAsr(const CapacidadEquipo(memoriaMb: 3072, nucleos: 2));
      expect(modelo.identificador, 'base');
    });

    test('en el límite de 1,5 GB recibe base', () {
      final modelo = elegirModeloAsr(const CapacidadEquipo(memoriaMb: 1536, nucleos: 2));
      expect(modelo.identificador, 'base');
    });

    test('por debajo de 1,5 GB recibe tiny aunque tenga muchos núcleos', () {
      final modelo = elegirModeloAsr(const CapacidadEquipo(memoriaMb: 1535, nucleos: 8));
      expect(modelo.identificador, 'tiny');
    });

    test('el catálogo de la versión 1 tiene tres modelos con su hash', () {
      expect(modeloTiny.sha256, 'be07e048e1e599ad46341c8d2a135645097a538221678b7acdd1b1919c6e1b21');
      expect(modeloBase.sha256, '60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe');
      expect(modeloSmall.sha256, '1be3a9b2063867b937e64e2ec7483364a79917e157fa98c5d94b5c1fffea987b');
    });
  });
}
