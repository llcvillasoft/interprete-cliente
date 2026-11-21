import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../dominio/bandeja_salida.dart';
import '../dominio/ventana.dart';

/// Error de la API: `error` del ErrorBody del contrato y su código de estado HTTP.
class ErrorApi implements Exception {
  ErrorApi(this.estado, this.mensaje);

  final int estado;
  final String mensaje;

  @override
  String toString() => 'ErrorApi($estado): $mensaje';
}

/// Sesión creada: `session.session_id` y `session.status` del contrato.
class SesionCreada {
  const SesionCreada({required this.id, required this.estado});

  final String id;

  /// Estado del contrato: created, running, paused, finishing, closed o abandoned.
  final String estado;
}

/// Lo que la pantalla Hoy y la sesión necesitan de la API.
abstract interface class ApiCliente {
  /// Factores f tras cada turno, en orden: `GET /v1/progress?metric=levels&direction=…`.
  Future<List<double>> nivelesDe(Direccion direccion);

  /// Crea una sesión de práctica: `POST /v1/sessions`.
  Future<SesionCreada> crearSesion();
}

class ClienteHttp implements ApiCliente, TransporteEventos {
  ClienteHttp({
    required this.baseUrl,
    required this.dispositivo,
    required this.secreto,
    http.Client? cliente,
  }) : _cliente = cliente ?? http.Client();

  final String baseUrl;
  final String dispositivo;
  final String secreto;
  final http.Client _cliente;
  String? _token;

  Future<String> _tokenVigente() async {
    final existente = _token;
    if (existente != null) return existente;
    final respuesta = await _cliente.post(
      Uri.parse('$baseUrl/v1/auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': dispositivo, 'secret': secreto}),
    );
    final token = _leer(respuesta)['token'] as String;
    _token = token;
    return token;
  }

  Map<String, dynamic> _leer(http.Response respuesta) {
    final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
    if (respuesta.statusCode >= 400) {
      throw ErrorApi(respuesta.statusCode, cuerpo['error'] as String? ?? 'error');
    }
    return cuerpo;
  }

  @override
  Future<List<double>> nivelesDe(Direccion direccion) async {
    final token = await _tokenVigente();
    final uri = Uri.parse('$baseUrl/v1/progress').replace(
      queryParameters: {'metric': 'levels', 'direction': direccion.clave},
    );
    final serie = _leer(await _cliente.get(uri, headers: {'Authorization': 'Bearer $token'}));
    final puntos = serie['points'] as List<dynamic>;
    return puntos
        .map((punto) => ((punto as Map<String, dynamic>)['f_after'] as num).toDouble())
        .toList();
  }

  @override
  Future<SesionCreada> crearSesion() async {
    final token = await _tokenVigente();
    final respuesta = await _cliente.post(
      Uri.parse('$baseUrl/v1/sessions'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    final sesion = _leer(respuesta)['session'] as Map<String, dynamic>;
    return SesionCreada(
      id: sesion['session_id'] as String,
      estado: sesion['status'] as String,
    );
  }

  /// Envía un lote a `POST /v1/events:batch`. Los fallos de red, el 401 y los 5xx son
  /// transitorios; el resto de 4xx son rechazos definitivos del lote.
  @override
  Future<ResultadoLote> enviarEventos(List<Evento> eventos) async {
    final respuesta = await _postEventos(eventos);
    if (respuesta.statusCode == 401) {
      _token = null;
      throw const ErrorTransitorio('token vencido');
    }
    if (respuesta.statusCode >= 500) {
      throw ErrorTransitorio('servidor ${respuesta.statusCode}');
    }
    if (respuesta.statusCode >= 400) {
      throw EventosRechazados(respuesta.statusCode, _motivo(respuesta));
    }
    final cuerpo = _leer(respuesta);
    return ResultadoLote(
      recibidos: cuerpo['received'] as int,
      nuevos: cuerpo['stored'] as int,
      duplicados: cuerpo['duplicates'] as int,
    );
  }

  Future<http.Response> _postEventos(List<Evento> eventos) async {
    try {
      final token = await _tokenVigente();
      return await _cliente.post(
        Uri.parse('$baseUrl/v1/events:batch'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'events': eventos}),
      );
    } on http.ClientException catch (error) {
      throw ErrorTransitorio(error.message);
    } on TimeoutException catch (error) {
      throw ErrorTransitorio(error.message ?? 'tiempo agotado');
    }
  }

  String _motivo(http.Response respuesta) {
    try {
      final cuerpo = jsonDecode(respuesta.body);
      if (cuerpo is Map<String, dynamic> && cuerpo['error'] is String) {
        return cuerpo['error'] as String;
      }
    } on FormatException {
      // El cuerpo no es JSON: basta con el código de estado.
    }
    return 'error ${respuesta.statusCode}';
  }
}
