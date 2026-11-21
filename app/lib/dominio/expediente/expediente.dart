import 'dart:convert';
import 'dart:math';

import '../bandeja_salida.dart' show Evento;
import 'almacen.dart';
import 'canonico.dart';
import 'cifrado.dart';
import 'huella.dart';
import 'uuid.dart';

const String _sufijoLocal = '#local';
const Set<String> _actores = {'user', 'system', 'worker', 'admin'};
final RegExp _formatoTipo = RegExp(r'^[A-Z][A-Za-z0-9]+$');
final RegExp _formatoHuella = RegExp(r'^[0-9a-f]{64}$');

/// El expediente local de un usuario: anexa eventos encadenados por huella, con el contenido personal sellado.
///
/// Cada evento lleva todas las claves del sobre del backend, con `null` cuando no hay valor. Así la huella que calcula
/// el cliente es la que recalcula el servidor cuando recibe el lote.
class Expediente {
  Expediente({
    required this.origen,
    required this.almacen,
    required this.cifrador,
    required int Function() ahora,
    required Random aleatorio,
  })  : _ahora = ahora,
        _aleatorio = aleatorio;

  /// Quién escribe en el expediente: el dispositivo, con su propia numeración y su propia cadena.
  final String origen;
  final AlmacenEventos almacen;
  final CifradorPersonal cifrador;
  final int Function() _ahora;
  final Random _aleatorio;

  var _ultimoMilisegundo = 0;
  var _ultimoContador = 0;

  /// Los anexos se hacen uno tras otro: cada uno lee la cabeza de la cadena que dejó el anterior.
  Future<void> _cola = Future<void>.value();

  /// Anexa un evento al flujo [flujo] y devuelve el evento tal como quedó guardado.
  ///
  /// [publico] se guarda en claro. [personal] se sella con la clave del usuario y se guarda como `payload.personal`.
  /// El [scope] se deduce del flujo: un flujo que termina en `#local` es local, y solo ahí.
  Future<Evento> anexar({
    required String flujo,
    required String tipo,
    required String manifiesto,
    Map<String, Object?> publico = const {},
    Map<String, Object?>? personal,
    String? scope,
    String actor = 'user',
    String? turnoId,
    String? causaId,
    String? correlacionId,
  }) {
    final turno = _cola.then(
      (_) => _anexar(
        flujo: flujo,
        tipo: tipo,
        manifiesto: manifiesto,
        publico: publico,
        personal: personal,
        scope: scope,
        actor: actor,
        turnoId: turnoId,
        causaId: causaId,
        correlacionId: correlacionId,
      ),
    );
    _cola = turno.then<void>((_) {}, onError: (_) {});
    return turno;
  }

  Future<Evento> _anexar({
    required String flujo,
    required String tipo,
    required String manifiesto,
    required Map<String, Object?> publico,
    required Map<String, Object?>? personal,
    required String? scope,
    required String actor,
    required String? turnoId,
    required String? causaId,
    required String? correlacionId,
  }) async {
    _validar(flujo: flujo, tipo: tipo, manifiesto: manifiesto, actor: actor, publico: publico);

    final esLocal = flujo.endsWith(_sufijoLocal);
    final ambito = scope ?? (esLocal ? 'local' : 'transportable');
    if (ambito != 'local' && ambito != 'transportable') {
      throw ArgumentError.value(ambito, 'scope', 'debe ser local o transportable');
    }
    if ((ambito == 'local') != esLocal) {
      throw ArgumentError.value(
        ambito,
        'scope',
        'un evento local va en un flujo que termina en $_sufijoLocal, y solo ahí (el flujo es $flujo)',
      );
    }

    final sello = _sellarTiempo();
    final eventoId = uuidV7(sello.milisegundos, _aleatorio);

    var seq = 0;
    var anterior = genesis;
    for (final existente in await almacen.leer(flujo)) {
      if (existente['origin'] == origen) {
        seq = existente['origin_seq'] as int;
        anterior = existente['hash'] as String;
      }
    }

    final payload = <String, Object?>{...publico};
    if (personal != null) {
      payload['personal'] = await cifrador.sellar(canonico(personal), aad: _aad(flujo, eventoId));
    }

    final cuerpo = <String, dynamic>{
      'event_id': eventoId,
      'type': tipo,
      'schema_version': 1,
      'stream': flujo,
      'turn_id': turnoId,
      'origin': origen,
      'origin_seq': seq + 1,
      'hlc': {'wall_ms': sello.milisegundos, 'counter': sello.contador},
      'occurred_at': _iso(sello.milisegundos),
      'scope': ambito,
      'actor': actor,
      'causation_id': causaId,
      'correlation_id': correlacionId,
      'manifest': manifiesto,
      'payload': payload,
      'prev_hash': anterior,
    };
    final evento = <String, dynamic>{...cuerpo, 'hash': huellaDeCuerpo(cuerpo)};

    await almacen.anexar(flujo, evento);
    return evento;
  }

  /// El contenido personal de un evento, abierto con la clave del usuario. Es `null` si el evento no lo tiene.
  Future<Map<String, Object?>?> leerPersonal(Evento evento) async {
    final payload = evento['payload'] as Map<String, dynamic>;
    final sellado = payload['personal'] as String?;
    if (sellado == null) return null;
    final claro = await cifrador.abrir(
      sellado,
      aad: _aad(evento['stream'] as String, evento['event_id'] as String),
    );
    return jsonDecode(claro) as Map<String, Object?>;
  }

  /// Un milisegundo que nunca retrocede y, si el reloj no avanza, un contador que sube (reloj híbrido).
  ({int milisegundos, int contador}) _sellarTiempo() {
    final ahora = _ahora();
    if (ahora > _ultimoMilisegundo) {
      _ultimoMilisegundo = ahora;
      _ultimoContador = 0;
    } else {
      _ultimoContador++;
    }
    return (milisegundos: _ultimoMilisegundo, contador: _ultimoContador);
  }

  void _validar({
    required String flujo,
    required String tipo,
    required String manifiesto,
    required String actor,
    required Map<String, Object?> publico,
  }) {
    if (flujo.isEmpty || flujo.length > 200) {
      throw ArgumentError.value(flujo, 'flujo', 'debe tener entre 1 y 200 caracteres');
    }
    if (!_formatoTipo.hasMatch(tipo)) {
      throw ArgumentError.value(tipo, 'tipo', 'no es un nombre de evento válido');
    }
    if (!_formatoHuella.hasMatch(manifiesto)) {
      throw ArgumentError.value(manifiesto, 'manifiesto', 'debe ser una huella SHA-256 en minúsculas');
    }
    if (!_actores.contains(actor)) {
      throw ArgumentError.value(actor, 'actor', 'no es un actor válido');
    }
    if (publico.containsKey('personal')) {
      throw ArgumentError.value(publico, 'publico', 'el campo personal va sellado, no entre los públicos');
    }
  }

  /// Lo que se ata al sellado: el flujo y el evento, para que un sellado no se pueda mover a otro evento.
  String _aad(String flujo, String eventoId) => '$flujo/$eventoId';
}

/// Texto ISO 8601 en UTC con milisegundos, como `occurred_at` del contrato.
String _iso(int milisegundos) {
  final momento = DateTime.fromMillisecondsSinceEpoch(milisegundos, isUtc: true);
  String dos(int valor) => valor.toString().padLeft(2, '0');
  final ms = momento.millisecond.toString().padLeft(3, '0');
  return '${momento.year.toString().padLeft(4, '0')}-${dos(momento.month)}-${dos(momento.day)}'
      'T${dos(momento.hour)}:${dos(momento.minute)}:${dos(momento.second)}.${ms}Z';
}
