import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../dominio/expediente/cifrado.dart';

/// Sella con AES-256-GCM. El texto sellado es `v1.` seguido, en base64url, del nonce, el cifrado y la etiqueta.
///
/// El nonce es aleatorio en cada sellado; por eso dos sellados del mismo texto no son iguales.
class CifradorAesGcm implements CifradorPersonal {
  CifradorAesGcm(List<int> clave, {Random? aleatorio})
      : assert(clave.length == 32, 'AES-256 necesita una clave de 32 bytes'),
        _clave = List<int>.unmodifiable(clave),
        _aleatorio = aleatorio ?? Random.secure();

  static const String _version = 'v1.';
  static const int _largoNonce = 12;
  static const int _largoEtiqueta = 16;

  final List<int> _clave;
  final Random _aleatorio;
  final AesGcm _algoritmo = AesGcm.with256bits();

  @override
  Future<String> sellar(String texto, {required String aad}) async {
    final nonce = List<int>.generate(_largoNonce, (_) => _aleatorio.nextInt(256));
    final caja = await _algoritmo.encrypt(
      utf8.encode(texto),
      secretKey: SecretKey(_clave),
      nonce: nonce,
      aad: utf8.encode(aad),
    );
    return '$_version${base64Url.encode(caja.concatenation())}';
  }

  @override
  Future<String> abrir(String sellado, {required String aad}) async {
    if (!sellado.startsWith(_version)) {
      throw const ErrorDeSellado('formato desconocido');
    }

    final List<int> bytes;
    try {
      bytes = base64Url.decode(sellado.substring(_version.length));
    } on FormatException {
      throw const ErrorDeSellado('base64url no válido');
    }

    final SecretBox caja;
    try {
      caja = SecretBox.fromConcatenation(bytes, nonceLength: _largoNonce, macLength: _largoEtiqueta);
    } catch (_) {
      throw const ErrorDeSellado('sellado demasiado corto');
    }

    try {
      final claro = await _algoritmo.decrypt(
        caja,
        secretKey: SecretKey(_clave),
        aad: utf8.encode(aad),
      );
      return utf8.decode(claro);
    } on SecretBoxAuthenticationError {
      throw const ErrorDeSellado('no se puede abrir: otra clave, otro evento o contenido alterado');
    }
  }
}
