import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/dominio/bandeja_salida.dart';

/// Evento mínimo: lo que la bandeja necesita es su orden y su identidad.
Evento evento(int n) => {
      'event_id': '00000000-0000-0000-0000-${n.toString().padLeft(12, '0')}',
      'type': 'SessionStarted',
      'origin_seq': n,
    };

String idDe(Evento e) => e['event_id'] as String;

/// Transporte con guion: cada elemento de [guion] responde a un envío en orden.
/// Un `Exception` se lanza; un `int` son los duplicados de ese lote; si el guion
/// se agota, el lote se acepta entero.
class TransporteGuionado implements TransporteEventos {
  TransporteGuionado([List<Object> guion = const []]) : guion = List.of(guion);

  final List<Object> guion;
  final List<List<Evento>> lotes = [];

  @override
  Future<ResultadoLote> enviarEventos(List<Evento> eventos) async {
    lotes.add(List.of(eventos));
    final paso = guion.isEmpty ? null : guion.removeAt(0);
    if (paso is Exception) throw paso;
    final duplicados = paso is int ? paso : 0;
    return ResultadoLote(
      recibidos: eventos.length,
      nuevos: eventos.length - duplicados,
      duplicados: duplicados,
    );
  }
}

void main() {
  late List<Duration> esperas;

  setUp(() {
    esperas = [];
  });

  Future<void> esperarSinTiempo(Duration duracion) async {
    esperas.add(duracion);
  }

  test('envía todos los eventos en orden y en lotes del tamaño máximo', () async {
    final transporte = TransporteGuionado();
    final bandeja = BandejaSalida(
      transporte: transporte,
      tamanoLote: 2,
      esperar: esperarSinTiempo,
    );
    bandeja.encolar([for (var n = 1; n <= 5; n++) evento(n)]);

    final resultado = await bandeja.sincronizar();

    expect(transporte.lotes.map((lote) => lote.length).toList(), equals([2, 2, 1]));
    expect(
      transporte.lotes.expand((lote) => lote).map(idDe).toList(),
      equals([for (var n = 1; n <= 5; n++) idDe(evento(n))]),
    );
    expect(resultado.nuevos, 5);
    expect(resultado.completa, isTrue);
    expect(bandeja.pendientes, 0);
  });

  test('sin conexión conserva los eventos y al volver los envía todos', () async {
    final transporte = TransporteGuionado([
      const ErrorTransitorio('sin red'),
      const ErrorTransitorio('sin red'),
      const ErrorTransitorio('sin red'),
    ]);
    final bandeja = BandejaSalida(
      transporte: transporte,
      reintentosMaximos: 2,
      esperar: esperarSinTiempo,
    );
    bandeja.encolar([for (var n = 1; n <= 4; n++) evento(n)]);

    final sinConexion = await bandeja.sincronizar();

    expect(sinConexion.completa, isFalse);
    expect(sinConexion.pendientes, 4);
    expect(bandeja.pendientes, 4);
    expect(esperas, equals([const Duration(seconds: 2), const Duration(seconds: 4)]));

    final alVolver = await bandeja.sincronizar();

    expect(alVolver.nuevos, 4);
    expect(alVolver.completa, isTrue);
    expect(bandeja.pendientes, 0);
    expect(
      transporte.lotes.last.map(idDe).toList(),
      equals([for (var n = 1; n <= 4; n++) idDe(evento(n))]),
    );
  });

  test('los duplicados del servidor salen de la bandeja sin contar como nuevos', () async {
    final transporte = TransporteGuionado([1]);
    final bandeja = BandejaSalida(transporte: transporte, esperar: esperarSinTiempo);
    bandeja.encolar([for (var n = 1; n <= 3; n++) evento(n)]);

    final resultado = await bandeja.sincronizar();

    expect(resultado.nuevos, 2);
    expect(resultado.duplicados, 1);
    expect(bandeja.pendientes, 0);
  });

  test('un lote rechazado de forma definitiva va a rechazados y no se reintenta', () async {
    final transporte = TransporteGuionado([const EventosRechazados(422, 'cuerpo no válido')]);
    final bandeja = BandejaSalida(transporte: transporte, esperar: esperarSinTiempo);
    bandeja.encolar([for (var n = 1; n <= 3; n++) evento(n)]);

    final resultado = await bandeja.sincronizar();

    expect(transporte.lotes.length, 1);
    expect(resultado.rechazados, 3);
    expect(bandeja.pendientes, 0);
    expect(bandeja.rechazados.map(idDe).toList(), equals([for (var n = 1; n <= 3; n++) idDe(evento(n))]));
    expect(esperas, isEmpty);
  });

  test('una sincronización que ya está en curso se reutiliza', () async {
    final transporte = TransporteGuionado();
    final bandeja = BandejaSalida(transporte: transporte, esperar: esperarSinTiempo);
    bandeja.encolar([evento(1), evento(2)]);

    final resultados = await Future.wait([bandeja.sincronizar(), bandeja.sincronizar()]);

    expect(transporte.lotes.length, 1);
    expect(resultados[0].nuevos, resultados[1].nuevos);
    expect(bandeja.pendientes, 0);
  });
}
