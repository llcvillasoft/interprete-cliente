import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/datos/cifrado_aes_gcm.dart';
import 'package:interprete_cliente/datos/expediente_memoria.dart';
import 'package:interprete_cliente/dominio/bandeja_salida.dart';
import 'package:interprete_cliente/dominio/expediente/eventos_dispositivo.dart';
import 'package:interprete_cliente/dominio/expediente/expediente.dart';

final String manifiesto = 'a' * 64;

const int instante = 1763510400000; // 2025-11-19T00:00:00.000Z

/// Un transporte que guarda cada lote enviado, para comprobar qué sale del dispositivo.
class TransporteRegistro implements TransporteEventos {
  final List<List<Evento>> lotes = [];

  @override
  Future<ResultadoLote> enviarEventos(List<Evento> eventos) async {
    lotes.add(List<Evento>.of(eventos));
    return ResultadoLote(recibidos: eventos.length, nuevos: eventos.length, duplicados: 0);
  }

  List<String> get tipos => [
        for (final lote in lotes)
          for (final evento in lote) evento['type'] as String,
      ];
}

void main() {
  late AlmacenEventosMemoria almacen;
  late TransporteRegistro transporte;
  late BandejaSalida bandeja;
  late RegistroEventosDispositivo registro;

  setUp(() {
    almacen = AlmacenEventosMemoria();
    transporte = TransporteRegistro();
    bandeja = BandejaSalida(transporte: transporte);
    registro = RegistroEventosDispositivo(
      expediente: Expediente(
        origen: 'dispositivo',
        almacen: almacen,
        cifrador: CifradorAesGcm(List<int>.filled(32, 9), aleatorio: Random(2)),
        ahora: () => instante,
        aleatorio: Random(5),
      ),
      bandeja: bandeja,
      usuario: 'ana',
      manifiesto: manifiesto,
    );
  });

  test('el catálogo del dispositivo usa los doce nombres del backend', () {
    expect(
      [for (final tipo in TipoEventoDispositivo.values) tipo.nombre],
      unorderedEquals([
        'SessionStarted',
        'SourcePlaybackEnded',
        'StimulusDisplayed',
        'WindowClosed',
        'CaptureRecorded',
        'CaptureFingerprinted',
        'VadSegmentsDetected',
        'TranscriptProduced',
        'DecisionRated',
        'AdviceRated',
        'ConsentGiven',
        'ConsentWithdrawn',
      ]),
    );
  });

  test('CaptureRecorded va solo al flujo local de la sesión y nunca se encola', () async {
    final evento = await registro.registrar(
      tipo: TipoEventoDispositivo.captureRecorded,
      sesion: 'sesion-1',
      carga: {'ubicacion': 'captura-1'},
    );

    expect(evento['stream'], 'sesion-1#local');
    expect(evento['scope'], 'local');
    expect(await almacen.leer('sesion-1#local'), hasLength(1));
    expect(await almacen.leer('sesion-1'), isEmpty);
    expect(bandeja.pendientes, 0);

    await bandeja.sincronizar();
    expect(transporte.lotes, isEmpty);
  });

  test('un evento de sesión va a su flujo y sale en el siguiente lote', () async {
    final evento = await registro.registrar(
      tipo: TipoEventoDispositivo.sessionStarted,
      sesion: 'sesion-1',
      carga: {'client': 'device-sim'},
    );

    expect(evento['stream'], 'sesion-1');
    expect(evento['scope'], 'transportable');
    expect(bandeja.pendientes, 1);

    await bandeja.sincronizar();
    expect(transporte.lotes.single.single['hash'], evento['hash']);
  });

  test('los consentimientos van al flujo del usuario', () async {
    final evento = await registro.registrar(
      tipo: TipoEventoDispositivo.consentGiven,
      sesion: 'sesion-1',
      carga: {'scope': 'recording', 'text_version': 'consent.v1'},
    );

    expect(evento['stream'], 'user:ana');
    expect(await almacen.leer('user:ana'), hasLength(1));
    expect(await almacen.leer('sesion-1'), isEmpty);

    await bandeja.sincronizar();
    expect(transporte.tipos, ['ConsentGiven']);
  });

  test('la transcripción guarda su texto sellado y no entra en la bandeja hasta resolver su formato', () async {
    final evento = await registro.registrar(
      tipo: TipoEventoDispositivo.transcriptProduced,
      sesion: 'sesion-1',
      turnoId: 'turno-1',
      carga: {'transcript': 'texto secreto', 'duracion_ms': 4200},
    );

    final payload = evento['payload'] as Map<String, dynamic>;
    expect(payload['personal'], startsWith('v1.'));
    expect(payload.containsKey('transcript'), isFalse);
    expect(payload['duracion_ms'], 4200);
    expect(await registro.expediente.leerPersonal(evento), {'transcript': 'texto secreto'});
    expect(bandeja.pendientes, 0);
  });

  test('los eventos de una sesión se encadenan por huella', () async {
    final primero = await registro.registrar(
      tipo: TipoEventoDispositivo.sessionStarted,
      sesion: 'sesion-1',
    );
    final segundo = await registro.registrar(
      tipo: TipoEventoDispositivo.windowClosed,
      sesion: 'sesion-1',
    );

    expect(segundo['prev_hash'], primero['hash']);
    expect(bandeja.pendientes, 2);
  });
}
