/// Dirección de la ventana sostenida, con las claves que usa el contrato.
enum Direccion {
  enEs('en_es', 'EN→ES', 'en-es'),
  esEn('es_en', 'ES→EN', 'es-en');

  const Direccion(this.clave, this.etiqueta, this.identificador);

  /// Valor de `direction` en `GET /v1/progress` (contrato: en_es o es_en).
  final String clave;

  /// Etiqueta visible en la pantalla.
  final String etiqueta;

  /// Parte final del identificador de semántica, `hoy.ventana.<identificador>`.
  final String identificador;
}

enum Tendencia {
  alAlza('al alza'),
  alaBaja('a la baja'),
  estable('estable');

  const Tendencia(this.texto);

  final String texto;
}

/// Ventana sostenida actual de una dirección y hacia dónde va.
class Ventana {
  const Ventana({required this.direccion, required this.factor, required this.tendencia});

  final Direccion direccion;
  final double factor;
  final Tendencia tendencia;
}

/// Calcula la ventana a partir de los factores f tras cada turno, en orden.
///
/// Supuesto AD-16: el factor actual es el último turno y la tendencia compara
/// los dos últimos. Sin turnos no hay ventana; con un solo turno, la tendencia es estable.
Ventana? ventanaDesde(Direccion direccion, List<double> factoresTrasCadaTurno) {
  if (factoresTrasCadaTurno.isEmpty) return null;
  final actual = factoresTrasCadaTurno.last;
  final tendencia = factoresTrasCadaTurno.length < 2
      ? Tendencia.estable
      : _tendencia(factoresTrasCadaTurno[factoresTrasCadaTurno.length - 2], actual);
  return Ventana(direccion: direccion, factor: actual, tendencia: tendencia);
}

Tendencia _tendencia(double anterior, double actual) {
  if (actual > anterior) return Tendencia.alAlza;
  if (actual < anterior) return Tendencia.alaBaja;
  return Tendencia.estable;
}

/// Factor tal como lo muestra la app: dos decimales y coma, como 1,40.
String formatoFactor(double factor) => factor.toStringAsFixed(2).replaceAll('.', ',');
