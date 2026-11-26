import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/datos/asr_isolate.dart';

final String? _biblioteca = Platform.environment['WHISPER_CORE_LIB'];
final String? _modelo = Platform.environment['WHISPER_MODELO_PRUEBA'];
final Object? _omitirSinBiblioteca =
    _biblioteca == null ? 'define WHISPER_CORE_LIB con la ruta de libwhisper_core' : null;
final Object? _omitirSinModelo =
    _omitirSinBiblioteca ?? (_modelo == null ? 'define WHISPER_MODELO_PRUEBA' : null);

void main() {
  group('transcripción en un isolate propio', () {
    test('un modelo que no existe rechaza la apertura con StateError', () async {
      await expectLater(
        WhisperEnIsolate.abrir(
          rutaBiblioteca: _biblioteca!,
          rutaModelo: '/ruta/que/no/existe/ggml-tiny.bin',
        ),
        throwsStateError,
      );
    }, skip: _omitirSinBiblioteca);

    test('rechaza un audio vacío sin cerrar el isolate', () async {
      final backend = await WhisperEnIsolate.abrir(
        rutaBiblioteca: _biblioteca!,
        rutaModelo: _modelo!,
      );
      addTearDown(backend.cerrar);
      await expectLater(
        backend.transcribir(Float32List(0), 'es'),
        throwsArgumentError,
      );
    }, skip: _omitirSinModelo);

    test('dos transcripciones seguidas devuelven sus propias respuestas', () async {
      final backend = await WhisperEnIsolate.abrir(
        rutaBiblioteca: _biblioteca!,
        rutaModelo: _modelo!,
      );
      addTearDown(backend.cerrar);
      final primera = await backend.transcribir(Float32List(16000), 'es');
      final segunda = await backend.transcribir(Float32List(8000), 'es');
      expect(primera, isA<List<RegistroWhisper>>());
      expect(segunda, isA<List<RegistroWhisper>>());
    }, skip: _omitirSinModelo);
  });
}
