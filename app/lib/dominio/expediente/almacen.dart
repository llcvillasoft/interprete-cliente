import '../bandeja_salida.dart' show Evento;

/// Expediente de solo anexión: cada flujo guarda sus eventos en el orden en que se escribieron. Nunca se modifican ni se
/// borran eventos desde aquí.
abstract interface class AlmacenEventos {
  /// Añade un evento al final del flujo. Falla si el `event_id` ya existe.
  Future<void> anexar(String flujo, Evento evento);

  /// Todos los eventos del flujo, en orden. Son copias: cambiarlas no cambia lo guardado.
  Future<List<Evento>> leer(String flujo);
}
