import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:interprete_cliente/datos/nucleo_audio.dart';

/// Comprueba que audio_core.dll va junto al ejecutable de la app de Windows y que el motor
/// la carga desde esa carpeta. Lo ejecuta el job windows de CI sobre la compilación que se
/// entrega. flutter test trata esta carpeta como integration_test porque su ruta empieza así,
/// y así no entra en las ejecuciones de Android ni de iOS.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('audio_core.dll está junto al ejecutable y se carga desde el paquete', () {
    expect(Platform.isWindows, isTrue, reason: 'esta prueba solo corre en Windows');

    final dll = File('${File(Platform.resolvedExecutable).parent.path}\\audio_core.dll');
    expect(dll.existsSync(), isTrue, reason: 'falta audio_core.dll junto al ejecutable: ${dll.path}');

    final motor = abrirMotorAudio(config: const ConfiguracionAudio(backendNulo: true));
    try {
      final cargada = _rutaDelModulo('audio_core.dll');
      expect(cargada, isNotNull, reason: 'audio_core.dll no está cargada en el proceso');
      expect(
        File(cargada!).resolveSymbolicLinksSync().toLowerCase(),
        dll.resolveSymbolicLinksSync().toLowerCase(),
        reason: 'audio_core.dll se cargó desde otra carpeta',
      );
    } finally {
      motor.cerrar();
    }
  });
}

typedef _ModuloC = Pointer<Void> Function(Pointer<Utf16> nombre);
typedef _Modulo = Pointer<Void> Function(Pointer<Utf16> nombre);
typedef _RutaC = Uint32 Function(Pointer<Void> modulo, Pointer<Utf16> ruta, Uint32 tamano);
typedef _Ruta = int Function(Pointer<Void> modulo, Pointer<Utf16> ruta, int tamano);

/// Ruta completa del módulo ya cargado con ese nombre, o null si no está cargado.
String? _rutaDelModulo(String nombre) {
  final kernel32 = DynamicLibrary.open('kernel32.dll');
  final obtenerModulo = kernel32.lookupFunction<_ModuloC, _Modulo>('GetModuleHandleW');
  final obtenerRuta = kernel32.lookupFunction<_RutaC, _Ruta>('GetModuleFileNameW');

  final nombreNativo = nombre.toNativeUtf16();
  final modulo = obtenerModulo(nombreNativo);
  calloc.free(nombreNativo);
  if (modulo.address == 0) return null;

  const tamano = 1024;
  final ruta = calloc<Uint16>(tamano).cast<Utf16>();
  try {
    final longitud = obtenerRuta(modulo, ruta, tamano);
    return ruta.toDartString(length: longitud);
  } finally {
    calloc.free(ruta);
  }
}
