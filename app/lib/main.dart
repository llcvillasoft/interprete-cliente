import 'package:flutter/material.dart';

import 'config.dart';
import 'datos/api_cliente.dart';
import 'presentacion/raiz_pantalla.dart';
import 'tokens.dart';

void main() {
  final api = ClienteHttp(
    baseUrl: urlApi,
    dispositivo: dispositivoApi,
    secreto: secretoApi,
  );
  runApp(AplicacionEntrenador(api: api));
}

class AplicacionEntrenador extends StatelessWidget {
  const AplicacionEntrenador({super.key, required this.api});

  final ApiCliente api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Entrenador de interpretación',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Tokens.fondo,
      ),
      home: RaizPantalla(api: api),
    );
  }
}
