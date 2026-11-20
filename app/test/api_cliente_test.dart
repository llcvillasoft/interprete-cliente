import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:interprete_cliente/datos/api_cliente.dart';
import 'package:interprete_cliente/dominio/ventana.dart';

http.Response _json(Object cuerpo, [int estado = 200]) =>
    http.Response(jsonEncode(cuerpo), estado, headers: {'content-type': 'application/json'});

void main() {
  test('pide un token y luego la serie de niveles de la dirección con ese token', () async {
    final pedidos = <http.Request>[];
    final cliente = MockClient((peticion) async {
      pedidos.add(peticion);
      if (peticion.url.path == '/v1/auth/token') {
        return _json({'token': 'token-1', 'expires_in': 3600, 'user': 'u', 'device_id': 'd'});
      }
      return _json({
        'metric': 'levels',
        'points': [
          {'f_after': 1.2},
          {'f_after': 1.4},
        ],
      });
    });
    final api = ClienteHttp(
      baseUrl: 'http://api.test',
      dispositivo: 'dispositivo-prueba-001',
      secreto: 'secreto-de-prueba',
      cliente: cliente,
    );

    final niveles = await api.nivelesDe(Direccion.enEs);

    expect(niveles, [1.2, 1.4]);
    final progreso = pedidos.last;
    expect(progreso.url.path, '/v1/progress');
    expect(progreso.url.queryParameters, {'metric': 'levels', 'direction': 'en_es'});
    expect(progreso.headers['Authorization'], 'Bearer token-1');
  });

  test('reutiliza el token mientras esté vigente', () async {
    var pedidosDeToken = 0;
    final cliente = MockClient((peticion) async {
      if (peticion.url.path == '/v1/auth/token') {
        pedidosDeToken++;
        return _json({'token': 'token-1', 'expires_in': 3600, 'user': 'u', 'device_id': 'd'});
      }
      return _json({'metric': 'levels', 'points': <Object>[]});
    });
    final api = ClienteHttp(baseUrl: 'http://api.test', dispositivo: 'd', secreto: 's', cliente: cliente);

    await api.nivelesDe(Direccion.enEs);
    await api.nivelesDe(Direccion.esEn);

    expect(pedidosDeToken, 1);
  });

  test('un error de la API llega con su código de estado', () async {
    final cliente = MockClient((peticion) async {
      if (peticion.url.path == '/v1/auth/token') {
        return _json({'error': 'unauthorized'}, 401);
      }
      return _json({'error': 'unauthorized'}, 401);
    });
    final api = ClienteHttp(baseUrl: 'http://api.test', dispositivo: 'd', secreto: 's', cliente: cliente);

    expect(
      () => api.nivelesDe(Direccion.enEs),
      throwsA(isA<ErrorApi>().having((error) => error.estado, 'estado', 401)),
    );
  });

  test('crear una sesión devuelve su identificador y su estado del contrato', () async {
    final cliente = MockClient((peticion) async {
      if (peticion.url.path == '/v1/auth/token') {
        return _json({'token': 'token-1', 'expires_in': 3600, 'user': 'u', 'device_id': 'd'});
      }
      return _json(
        {
          'session': {
            'session_id': 'sesion-prueba-001',
            'turns_scheduled': 0,
            'turns_decided': 0,
            'finished': false,
            'events': 1,
            'knobs': <String>[],
            'status': 'created',
            'paused': false,
            'mode': 'continuous',
          },
          'event': {},
        },
        201,
      );
    });
    final api = ClienteHttp(baseUrl: 'http://api.test', dispositivo: 'd', secreto: 's', cliente: cliente);

    final sesion = await api.crearSesion();

    expect(sesion.id, 'sesion-prueba-001');
    expect(sesion.estado, 'created');
  });
}
