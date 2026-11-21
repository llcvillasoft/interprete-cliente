import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/datos/cifrado_aes_gcm.dart';
import 'package:interprete_cliente/datos/expediente_memoria.dart';
import 'package:interprete_cliente/dominio/bandeja_salida.dart';
import 'package:interprete_cliente/dominio/expediente/cadena.dart';
import 'package:interprete_cliente/dominio/expediente/cifrado.dart';
import 'package:interprete_cliente/dominio/expediente/claves.dart';
import 'package:interprete_cliente/dominio/expediente/expediente.dart';
import 'package:interprete_cliente/dominio/expediente/huella.dart';
import 'package:interprete_cliente/dominio/expediente/uuid.dart';

final String manifiesto = 'a' * 64;

const int instante = 1763510400000; // 2025-11-19T00:00:00.000Z

List<int> claveDePrueba() => List<int>.filled(32, 9);

Map<String, dynamic> sinHash(Evento evento) => Map<String, dynamic>.of(evento)..remove('hash');

void main() {
  late AlmacenEventosMemoria almacen;
  late CifradorAesGcm cifrador;
  late int reloj;

  Expediente expediente() => Expediente(
        origen: 'dispositivo',
        almacen: almacen,
        cifrador: cifrador,
        ahora: () => reloj,
        aleatorio: Random(5),
      );

  setUp(() {
    almacen = AlmacenEventosMemoria();
    cifrador = CifradorAesGcm(claveDePrueba(), aleatorio: Random(2));
    reloj = instante;
  });

  group('anexar al expediente', () {
    test('numera cada origen y encadena cada evento con el anterior', () async {
      final e = expediente();

      final a = await e.anexar(
        flujo: 'sesion-1',
        tipo: 'SessionStarted',
        manifiesto: manifiesto,
        publico: {'modo': 'continua'},
      );
      final b = await e.anexar(
        flujo: 'sesion-1',
        tipo: 'WindowClosed',
        manifiesto: manifiesto,
        publico: {'vencida': true},
      );

      expect(a['origin_seq'], 1);
      expect(b['origin_seq'], 2);
      expect(a['prev_hash'], genesis);
      expect(b['prev_hash'], a['hash']);
      expect(a['hash'], huellaDeCuerpo(sinHash(a)));
      expect(b['hash'], huellaDeCuerpo(sinHash(b)));
    });

    test('cada evento trae todas las claves del sobre del backend, con null si no hay valor', () async {
      final evento = await expediente().anexar(
        flujo: 'sesion-1',
        tipo: 'SessionStarted',
        manifiesto: manifiesto,
      );

      expect(
        evento.keys,
        containsAll(<String>[
          'event_id',
          'type',
          'schema_version',
          'stream',
          'turn_id',
          'origin',
          'origin_seq',
          'hlc',
          'occurred_at',
          'scope',
          'actor',
          'causation_id',
          'correlation_id',
          'manifest',
          'payload',
          'prev_hash',
          'hash',
        ]),
      );
      expect(evento.containsKey('turn_id'), isTrue);
      expect(evento['turn_id'], isNull);
    });

    test('el reloj híbrido avanza aunque el reloj de pared no se mueva', () async {
      final e = expediente();

      final a = await e.anexar(flujo: 'sesion-1', tipo: 'SessionStarted', manifiesto: manifiesto);
      final b = await e.anexar(flujo: 'sesion-1', tipo: 'SessionStarted', manifiesto: manifiesto);
      reloj += 5000;
      final c = await e.anexar(flujo: 'sesion-1', tipo: 'SessionStarted', manifiesto: manifiesto);

      expect(a['hlc'], {'wall_ms': instante, 'counter': 0});
      expect(b['hlc'], {'wall_ms': instante, 'counter': 1});
      expect(c['hlc'], {'wall_ms': instante + 5000, 'counter': 0});
      expect(c['occurred_at'], '2025-11-19T00:00:05.000Z');
    });

    test('los eventos locales van en el flujo local, con su propia cadena', () async {
      final evento = await expediente().anexar(
        flujo: 'sesion-1#local',
        tipo: 'CaptureRecorded',
        manifiesto: manifiesto,
        publico: {'bytes': 1024},
      );

      expect(evento['scope'], 'local');
      expect(evento['origin_seq'], 1);
      expect(evento['prev_hash'], genesis);
    });

    test('rechaza un evento local fuera del flujo local y uno de flujo local no local', () async {
      await expectLater(
        expediente().anexar(
          flujo: 'sesion-1',
          tipo: 'CaptureRecorded',
          manifiesto: manifiesto,
          scope: 'local',
        ),
        throwsArgumentError,
      );
      await expectLater(
        expediente().anexar(
          flujo: 'sesion-1#local',
          tipo: 'CaptureRecorded',
          manifiesto: manifiesto,
          scope: 'transportable',
        ),
        throwsArgumentError,
      );
    });

    test('rechaza poner el campo personal entre los públicos', () async {
      await expectLater(
        expediente().anexar(
          flujo: 'sesion-1',
          tipo: 'TranscriptProduced',
          manifiesto: manifiesto,
          publico: {'personal': 'texto'},
        ),
        throwsArgumentError,
      );
    });
  });

  group('expediente verificable', () {
    test('verifica su propia cadena', () async {
      final e = expediente();
      for (var n = 0; n < 3; n++) {
        await e.anexar(flujo: 'sesion-1', tipo: 'SessionStarted', manifiesto: manifiesto);
      }

      final informe = verificarCadena(await almacen.leer('sesion-1'), flujo: 'sesion-1');

      expect(informe.ok, isTrue, reason: '${informe.problemas}');
      expect(informe.eventos, 3);
    });

    test('anexos pedidos a la vez al mismo flujo quedan encadenados sin huecos', () async {
      final e = expediente();

      await Future.wait([
        for (var n = 0; n < 5; n++)
          e.anexar(flujo: 'sesion-1', tipo: 'SessionStarted', manifiesto: manifiesto),
      ]);

      final informe = verificarCadena(await almacen.leer('sesion-1'), flujo: 'sesion-1');
      expect(informe.ok, isTrue, reason: '${informe.problemas}');
      expect(informe.eventos, 5);
    });

    test('el contenido personal se guarda sellado y se lee con el expediente', () async {
      final e = expediente();
      await e.anexar(
        flujo: 'sesion-1',
        tipo: 'TranscriptProduced',
        manifiesto: manifiesto,
        publico: {'palabras': 3},
        personal: {'transcripcion': 'texto secreto'},
      );

      final guardado = (await almacen.leer('sesion-1')).single;
      final payload = guardado['payload'] as Map<String, dynamic>;

      expect(jsonEncode(guardado), isNot(contains('texto secreto')));
      expect(payload['personal'], startsWith('v1.'));
      expect(payload['palabras'], 3);
      expect(await e.leerPersonal(guardado), {'transcripcion': 'texto secreto'});
    });

    test('sin clave, el contenido personal queda ilegible y la cadena sigue verificando', () async {
      final claves = AlmacenClavesMemoria(aleatorio: Random(4));
      final cifradorDeAna = CifradorAesGcm(await claves.claveDeUsuario('ana'), aleatorio: Random(2));
      final e = Expediente(
        origen: 'dispositivo',
        almacen: almacen,
        cifrador: cifradorDeAna,
        ahora: () => reloj,
        aleatorio: Random(5),
      );
      await e.anexar(
        flujo: 'sesion-1',
        tipo: 'TranscriptProduced',
        manifiesto: manifiesto,
        personal: {'texto': 'privado'},
      );

      await claves.destruirClave('ana');
      await expectLater(claves.claveDeUsuario('ana'), throwsA(isA<ClaveDestruida>()));

      final eventos = await almacen.leer('sesion-1');
      expect(verificarCadena(eventos, flujo: 'sesion-1').ok, isTrue);
      expect((eventos.single['payload'] as Map<String, dynamic>)['personal'], startsWith('v1.'));
      await expectLater(
        CifradorAesGcm(List<int>.filled(32, 0)).abrir(
          (eventos.single['payload'] as Map<String, dynamic>)['personal'] as String,
          aad: 'sesion-1/${eventos.single['event_id']}',
        ),
        throwsA(isA<ErrorDeSellado>()),
      );
    });
  });

  group('almacén de eventos', () {
    test('rechaza un event_id repetido y devuelve copias de lo guardado', () async {
      final a = await expediente().anexar(flujo: 'sesion-1', tipo: 'SessionStarted', manifiesto: manifiesto);

      await expectLater(almacen.anexar('sesion-1', a), throwsStateError);

      final copia = (await almacen.leer('sesion-1')).single;
      copia['payload'] = {'alterado': true};
      expect((await almacen.leer('sesion-1')).single['payload'], isNot({'alterado': true}));
    });
  });

  group('identificador de evento (UUID versión 7)', () {
    test('tiene el formato del contrato, versión 7 y variante RFC 4122', () {
      final id = uuidV7(instante, Random(3));

      expect(
        id,
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
      );
    });

    test('empieza por los milisegundos, así que se ordena por tiempo', () {
      final antes = uuidV7(instante, Random(3));
      final despues = uuidV7(instante + 1, Random(3));

      expect(antes.replaceAll('-', '').substring(0, 12), '019a99693400');
      expect(antes.compareTo(despues), lessThan(0));
    });

    test('dos identificadores del mismo milisegundo no coinciden', () {
      final rnd = Random(3);

      expect(uuidV7(instante, rnd), isNot(uuidV7(instante, rnd)));
    });
  });
}
