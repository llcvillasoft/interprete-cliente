import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:interprete_cliente/datos/api_cliente.dart';

http.Response _json(Object cuerpo, [int estado = 200]) =>
    http.Response(jsonEncode(cuerpo), estado, headers: {'content-type': 'application/json'});

ClienteHttp _clienteCon(http.Client cliente) => ClienteHttp(
      baseUrl: 'http://api.test',
      dispositivo: 'dispositivo-prueba-001',
      secreto: 'secreto-de-prueba',
      cliente: cliente,
    );

void main() {
  test('los consentimientos vigentes salen de GET /v1/me/consents con el token', () async {
    final pedidos = <http.Request>[];
    final api = _clienteCon(MockClient((peticion) async {
      pedidos.add(peticion);
      if (peticion.url.path == '/v1/auth/token') return _json({'token': 'token-1'});
      return _json({
        'consents': {'audio': false, 'entrenamiento': true},
      });
    }));

    final consentidos = await api.consentimientos();

    expect(consentidos, {'audio': false, 'entrenamiento': true});
    final lectura = pedidos.last;
    expect(lectura.method, 'GET');
    expect(lectura.url.path, '/v1/me/consents');
    expect(lectura.headers['Authorization'], 'Bearer token-1');
  });

  test('exportar hace POST /v1/exports y devuelve cuántos flujos trae el paquete', () async {
    final pedidos = <http.Request>[];
    final api = _clienteCon(MockClient((peticion) async {
      pedidos.add(peticion);
      if (peticion.url.path == '/v1/auth/token') return _json({'token': 'token-1'});
      return _json({
        'schema': 'interp.export',
        'user': 'usuario-prueba-001',
        'streams': {'user:usuario-prueba-001': [], 'sesion-1#local': []},
        'manifests': {},
        'opened': {},
      });
    }));

    final exportacion = await api.exportar();

    expect(exportacion.usuario, 'usuario-prueba-001');
    expect(exportacion.flujos, 2);
    expect(pedidos.last.method, 'POST');
    expect(pedidos.last.url.path, '/v1/exports');
  });

  test('borrar la cuenta hace DELETE /v1/me y devuelve lo destruido', () async {
    final pedidos = <http.Request>[];
    final api = _clienteCon(MockClient((peticion) async {
      pedidos.add(peticion);
      if (peticion.url.path == '/v1/auth/token') return _json({'token': 'token-1'});
      return _json({
        'user': 'usuario-prueba-001',
        'key_destroyed': true,
        'sessions': 3,
      });
    }));

    final resultado = await api.borrarCuenta();

    expect(resultado.usuario, 'usuario-prueba-001');
    expect(resultado.claveDestruida, isTrue);
    expect(resultado.sesiones, 3);
    expect(pedidos.last.method, 'DELETE');
    expect(pedidos.last.url.path, '/v1/me');
  });

  test('un error de la API en consentimientos llega como ErrorApi con su mensaje', () async {
    final api = _clienteCon(MockClient((peticion) async {
      if (peticion.url.path == '/v1/auth/token') return _json({'token': 'token-1'});
      return _json({'error': 'no_autorizado'}, 403);
    }));

    expect(
      () => api.consentimientos(),
      throwsA(
        isA<ErrorApi>()
            .having((error) => error.estado, 'estado', 403)
            .having((error) => error.mensaje, 'mensaje', 'no_autorizado'),
      ),
    );
  });
}
