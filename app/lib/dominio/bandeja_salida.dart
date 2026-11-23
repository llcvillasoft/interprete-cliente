import 'dart:async';
import 'dart:math' as math;

/// Evento del expediente tal como lo recibe `POST /v1/events:batch`.
typedef Evento = Map<String, dynamic>;

/// `SyncResult` del contrato: cuántos eventos del lote eran nuevos.
class ResultadoLote {
  const ResultadoLote({
    required this.recibidos,
    required this.nuevos,
    required this.duplicados,
  });

  final int recibidos;
  final int nuevos;
  final int duplicados;
}

/// Fallo que se reintenta: sin conexión, servidor caído o token vencido.
class ErrorTransitorio implements Exception {
  const ErrorTransitorio(this.motivo);

  final String motivo;

  @override
  String toString() => 'ErrorTransitorio: $motivo';
}

/// Fallo que no se reintenta: el servidor rechaza el lote tal como está.
class EventosRechazados implements Exception {
  const EventosRechazados(this.estado, this.motivo);

  final int estado;
  final String motivo;

  @override
  String toString() => 'EventosRechazados($estado): $motivo';
}

/// Lo que la bandeja necesita del servidor: enviar un lote de eventos.
abstract interface class TransporteEventos {
  Future<ResultadoLote> enviarEventos(List<Evento> eventos);
}

/// Resumen de una sincronización, completa o interrumpida.
class ResultadoSincronizacion {
  const ResultadoSincronizacion({
    required this.nuevos,
    required this.duplicados,
    required this.rechazados,
    required this.pendientes,
  });

  final int nuevos;
  final int duplicados;
  final int rechazados;
  final int pendientes;

  /// Verdadero cuando la bandeja ha quedado vacía.
  bool get completa => pendientes == 0;
}

/// Bandeja de salida: guarda los eventos en orden y los envía en lotes.
///
/// Un lote sale de la bandeja solo cuando el servidor lo acepta o lo rechaza
/// de forma definitiva. Un fallo transitorio se reintenta con espera
/// exponencial; si se agotan los reintentos, los eventos siguen pendientes
/// para la siguiente sincronización. Como el servidor es idempotente por
/// `event_id`, reenviar un lote ya recibido no duplica nada.
class BandejaSalida {
  BandejaSalida({
    required TransporteEventos transporte,
    this.tamanoLote = 1000,
    this.reintentosMaximos = 5,
    this.esperaBase = const Duration(seconds: 2),
    Future<void> Function(Duration)? esperar,
  })  : assert(tamanoLote > 0 && tamanoLote <= 1000, 'el contrato admite hasta 1000 eventos por lote'),
        _transporte = transporte,
        _esperar = esperar ?? ((duracion) => Future<void>.delayed(duracion));

  final TransporteEventos _transporte;
  final int tamanoLote;
  final int reintentosMaximos;
  final Duration esperaBase;
  final Future<void> Function(Duration) _esperar;

  final List<Evento> _pendientes = [];
  final List<Evento> _rechazados = [];
  final StreamController<void> _cambios = StreamController<void>.broadcast();
  Future<ResultadoSincronizacion>? _enCurso;
  ResultadoSincronizacion? _ultima;

  int get pendientes => _pendientes.length;

  List<Evento> get rechazados => List.unmodifiable(_rechazados);

  /// El resultado de la última sincronización que terminó; `null` si todavía no ha terminado ninguna.
  ResultadoSincronizacion? get ultimaSincronizacion => _ultima;

  /// Avisa cada vez que cambian los pendientes, los rechazados o el resultado de una sincronización.
  Stream<void> get cambios => _cambios.stream;

  /// Añade eventos al final de la bandeja, en el orden recibido.
  void encolar(Iterable<Evento> eventos) {
    _pendientes.addAll(eventos);
    _avisar();
  }

  /// Envía lo pendiente. Si ya hay una sincronización en curso, devuelve esa.
  Future<ResultadoSincronizacion> sincronizar() {
    final enCurso = _enCurso;
    if (enCurso != null) return enCurso;
    final nueva = _sincronizar();
    _enCurso = nueva;
    return nueva.whenComplete(() => _enCurso = null);
  }

  Future<ResultadoSincronizacion> _sincronizar() async {
    var nuevos = 0;
    var duplicados = 0;
    var rechazados = 0;
    var intentos = 0;

    while (_pendientes.isNotEmpty) {
      final lote = List<Evento>.of(_pendientes.take(tamanoLote));
      try {
        final resultado = await _transporte.enviarEventos(lote);
        _pendientes.removeRange(0, lote.length);
        nuevos += resultado.nuevos;
        duplicados += resultado.duplicados;
        intentos = 0;
        _avisar();
      } on ErrorTransitorio {
        intentos += 1;
        if (intentos > reintentosMaximos) break;
        await _esperar(esperaBase * math.pow(2, intentos - 1).toInt());
      } on EventosRechazados {
        _rechazados.addAll(lote);
        _pendientes.removeRange(0, lote.length);
        rechazados += lote.length;
        intentos = 0;
        _avisar();
      }
    }

    final resultado = ResultadoSincronizacion(
      nuevos: nuevos,
      duplicados: duplicados,
      rechazados: rechazados,
      pendientes: _pendientes.length,
    );
    _ultima = resultado;
    _avisar();
    return resultado;
  }

  void _avisar() {
    if (!_cambios.isClosed) _cambios.add(null);
  }
}
