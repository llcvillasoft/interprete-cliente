import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/datos/asr_whisper_nativo.dart';

final String? _biblioteca = Platform.environment['WHISPER_CORE_LIB'];
final String? _modelo = Platform.environment['WHISPER_MODELO_PRUEBA'];
final Object? _omitirSinBiblioteca =
    _biblioteca == null ? 'define WHISPER_CORE_LIB con la ruta de libwhisper_core' : null;

void main() {
  group('envoltura FFI de whisper.cpp', () {
    test('un modelo que no existe lanza StateError', () {
      expect(
        () => WhisperNativo.abrir(
          rutaBiblioteca: _biblioteca!,
          rutaModelo: '/ruta/que/no/existe/ggml-tiny.bin',
        ),
        throwsStateError,
      );
    }, skip: _omitirSinBiblioteca);

    test('rechaza un audio vacío antes de llamar a la biblioteca', () async {
      final backend = WhisperNativo.abrir(
        rutaBiblioteca: _biblioteca!,
        rutaModelo: _modelo ?? '/ruta/inexistente.bin',
      );
      addTearDown(backend.cerrar);
      await expectLater(
        backend.transcribir(Float32List(0), 'es'),
        throwsArgumentError,
      );
    }, skip: _omitirSinBiblioteca ?? (_modelo == null ? 'define WHISPER_MODELO_PRUEBA' : null));

    test('transcribe silencio sin errores y devuelve una lista', () async {
      final backend = WhisperNativo.abrir(
        rutaBiblioteca: _biblioteca!,
        rutaModelo: _modelo!,
      );
      addTearDown(backend.cerrar);
      final registros = await backend.transcribir(Float32List(16000), 'es');
      expect(registros, isA<List<RegistroWhisper>>());
    }, skip: _omitirSinBiblioteca ?? (_modelo == null ? 'define WHISPER_MODELO_PRUEBA' : null));
  });
}
