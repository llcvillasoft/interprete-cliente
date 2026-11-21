import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'canonico.dart';

/// El `prev_hash` del primer evento de cada origen dentro de un flujo: 64 ceros, como en el backend.
final String genesis = '0' * 64;

/// La huella de un cuerpo de evento: SHA-256 de su forma canónica, sin el campo `hash`.
String huellaDeCuerpo(Map<String, dynamic> cuerpo) {
  final sinHash = Map<String, dynamic>.of(cuerpo)..remove('hash');
  return huellaDeTexto(canonico(sinHash));
}

/// SHA-256 en hexadecimal minúscula de un texto en UTF-8.
String huellaDeTexto(String texto) => sha256.convert(utf8.encode(texto)).toString();
