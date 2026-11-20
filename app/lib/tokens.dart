import 'package:flutter/material.dart';

/// Tokens de color del diseño (Anexo A y documento de frontend).
abstract final class Tokens {
  static const fondo = Color(0xFF0D1012);
  static const superficie = Color(0xFF161A1E);
  static const linea = Color(0xFF2A3138);
  static const enEs = Color(0xFF5AD4C4);
  static const esEn = Color(0xFF7DB7FF);
  static const ambar = Color(0xFFE9C46A);
  static const naranja = Color(0xFFFF9A57);
  static const rojo = Color(0xFFFF6F61);
}

/// Anchos de la navegación: compacto (barra inferior), medio (riel angosto) y amplio (riel con etiquetas).
enum AnchoPantalla { compacto, medio, amplio }

AnchoPantalla anchoDe(double ancho) {
  if (ancho < 600) return AnchoPantalla.compacto;
  if (ancho <= 1024) return AnchoPantalla.medio;
  return AnchoPantalla.amplio;
}
