/// Sella y abre el contenido personal de un evento con la clave del usuario.
///
/// El contenido sellado es lo que se guarda y lo que entra en la huella del evento. Así, borrar la clave deja el
/// contenido ilegible y la cadena sigue verificando.
abstract interface class CifradorPersonal {
  /// Sella [texto] atado a [aad], que identifica el evento al que pertenece.
  Future<String> sellar(String texto, {required String aad});

  /// Abre un sellado. Falla con [ErrorDeSellado] si la clave no es la suya, si el [aad] no coincide o si está alterado.
  Future<String> abrir(String sellado, {required String aad});
}

/// El contenido no se puede abrir: otra clave, otro evento, alteración o un formato desconocido.
class ErrorDeSellado implements Exception {
  const ErrorDeSellado(this.motivo);

  final String motivo;

  @override
  String toString() => 'ErrorDeSellado: $motivo';
}
