import 'package:flutter/material.dart';

import 'config.dart';
import 'datos/api_cliente.dart';
import 'dominio/bandeja_salida.dart';
import 'presentacion/raiz_pantalla.dart';
import 'tokens.dart';

void main() {
  final api = ClienteHttp(
    baseUrl: urlApi,
    dispositivo: dispositivoApi,
    secreto: secretoApi,
  );
  final bandeja = BandejaSalida(transporte: api);
  runApp(AplicacionEntrenador(api: api, bandeja: bandeja));
}

class AplicacionEntrenador extends StatelessWidget {
  const AplicacionEntrenador({super.key, required this.api, required this.bandeja});

  final ApiCliente api;
  final BandejaSalida bandeja;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Entrenador de interpretación',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Tokens.fondo,
      ),
      home: RaizPantalla(api: api, bandeja: bandeja),
    );
  }
}
