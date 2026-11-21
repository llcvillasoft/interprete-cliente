import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:interprete_cliente/datos/api_cliente.dart';
import 'package:interprete_cliente/dominio/bandeja_salida.dart';

http.Response _json(Object cuerpo, [int estado = 200]) =>
    http.Response(jsonEncode(cuerpo), estado, headers: {'content-type': 'application/json'});

Map<String, dynamic> _tokenRespuesta() =>
    {'token': 'token-1', 'expires_in': 3600, 'user': 'u', 'device_id': 'd'};

Map<String, dynamic> _sincronizado({int nuevos = 1, int duplicados = 0}) => {
      'received': nuevos + duplicados,
      'stored': nuevos,
      'duplicates': duplicados,
      'stored_ids': <String>[],
    };

ClienteHttp _api(http.Client transporte) => ClienteHttp(
      baseUrl: 'http://api.test',
      dispositivo: 'd',
      secreto: 's',
      cliente: transporte,
    );

const List<Evento> eventos = [
  {'event_id': '00000000-0000-0000-0000-000000000001', 'type': 'SessionStarted', 'origin_seq': 1},
];

void main() {
  test('envía el lote con el token y devuelve lo que informa el servidor', () async {
    final pedidos = <http.Request>[];
    final transporte = MockClient((peticion) async {
      pedidos.add(peticion);
      if (peticion.url.path == '/v1/auth/token') return _json(_tokenRespuesta());
      return _json(_sincronizado(nuevos: 1, duplicados: 1));
    });

    final resultado = await _api(transporte).enviarEventos(eventos);

    expect(resultado.nuevos, 1);
    expect(resultado.duplicados, 1);
    final envio = pedidos.last;
    expect(envio.url.path, '/v1/events:batch');
    expect(envio.headers['Authorization'], 'Bearer token-1');
    expect(jsonDecode(envio.body), equals({'events': eventos}));
  });

  test('un 500 es transitorio para que la bandeja reintente', () async {
    final transporte = MockClient((peticion) async {
      if (peticion.url.path == '/v1/auth/token') return _json(_tokenRespuesta());
      return _json({'error': 'caída'}, 500);
    });

    await expectLater(
      _api(transporte).enviarEventos(eventos),
      throwsA(isA<ErrorTransitorio>()),
    );
  });

  test('un 422 es un rechazo definitivo con el motivo del servidor', () async {
    final transporte = MockClient((peticion) async {
      if (peticion.url.path == '/v1/auth/token') return _json(_tokenRespuesta());
      return _json({'error': 'cuerpo no válido'}, 422);
    });

    await expectLater(
      _api(transporte).enviarEventos(eventos),
      throwsA(
        isA<EventosRechazados>()
            .having((error) => error.estado, 'estado', 422)
            .having((error) => error.motivo, 'motivo', 'cuerpo no válido'),
      ),
    );
  });

  test('un 401 es transitorio y la siguiente llamada pide un token nuevo', () async {
    var pidiosToken = 0;
    var envios = 0;
    final transporte = MockClient((peticion) async {
      if (peticion.url.path == '/v1/auth/token') {
        pidiosToken += 1;
        return _json(_tokenRespuesta());
      }
      envios += 1;
      if (envios == 1) return _json({'error': 'token vencido'}, 401);
      return _json(_sincronizado());
    });
    final api = _api(transporte);

    await expectLater(api.enviarEventos(eventos), throwsA(isA<ErrorTransitorio>()));
    final resultado = await api.enviarEventos(eventos);

    expect(resultado.nuevos, 1);
    expect(pidiosToken, 2);
  });

  test('un fallo de red es transitorio', () async {
    final transporte = MockClient((peticion) async {
      if (peticion.url.path == '/v1/auth/token') return _json(_tokenRespuesta());
      throw http.ClientException('sin red', peticion.url);
    });

    await expectLater(
      _api(transporte).enviarEventos(eventos),
      throwsA(isA<ErrorTransitorio>()),
    );
  });
}
