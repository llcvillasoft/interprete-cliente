import 'dart:math';

/// Un UUID versión 7 (RFC 9562): los 48 bits de milisegundos van primero, así que los eventos se ordenan por tiempo.
///
/// El resto son bits aleatorios. El backend emite el mismo formato, que el contrato acepta como `event_id`.
String uuidV7(int milisegundos, Random aleatorio) {
  final bytes = List<int>.filled(16, 0);
  var resto = milisegundos;
  for (var i = 5; i >= 0; i--) {
    bytes[i] = resto & 0xff;
    resto >>= 8;
  }
  for (var i = 6; i < 16; i++) {
    bytes[i] = aleatorio.nextInt(256);
  }
  bytes[6] = (bytes[6] & 0x0f) | 0x70; // versión 7
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC 4122

  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
