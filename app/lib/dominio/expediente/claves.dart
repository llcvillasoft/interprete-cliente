/// La clave de cada usuario, guardada en el almacén seguro del sistema (§4.5 del documento maestro).
///
/// Ninguna clase de dominio guarda una clave en claro: solo pide esta interfaz.
abstract interface class AlmacenClaves {
  /// La clave de 32 bytes del usuario. La crea la primera vez que se pide.
  Future<List<int>> claveDeUsuario(String usuario);

  /// Destruye la clave del usuario. El contenido sellado con ella queda ilegible.
  Future<void> destruirClave(String usuario);
}

/// Se pidió la clave de un usuario cuya clave ya fue destruida. No se crea otra: el expediente anterior no se puede
/// recuperar y no se mezcla con uno nuevo.
class ClaveDestruida implements Exception {
  const ClaveDestruida(this.usuario);

  final String usuario;

  @override
  String toString() => 'ClaveDestruida: la clave de $usuario fue destruida y no se recrea';
}
