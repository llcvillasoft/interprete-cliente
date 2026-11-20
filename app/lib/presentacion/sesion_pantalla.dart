import 'package:flutter/material.dart';

import '../datos/api_cliente.dart';
import '../tokens.dart';

/// Sesión de práctica: sin navegación, con el anillo de la ventana sin cifras.
class SesionPantalla extends StatelessWidget {
  const SesionPantalla({super.key, required this.sesion});

  final SesionCreada sesion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sesión de práctica')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              identifier: 'sesion.anillo',
              label: 'Ventana de grabación',
              child: const SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(painter: _AnilloPainter()),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              identifier: 'sesion.estado',
              child: Text(_etiqueta(sesion.estado), style: const TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }

  String _etiqueta(String estado) => switch (estado) {
        'created' => 'Lista para grabar',
        'running' => 'Grabando',
        'paused' => 'En pausa',
        _ => 'Estado no previsto',
      };
}

class _AnilloPainter extends CustomPainter {
  const _AnilloPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.shortestSide / 2 - 8;
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = Tokens.linea;
    canvas.drawCircle(centro, radio, trazo);
  }

  @override
  bool shouldRepaint(covariant CustomPainter anterior) => false;
}
