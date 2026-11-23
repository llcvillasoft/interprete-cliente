import 'package:flutter/material.dart';

import '../dominio/bandeja_salida.dart';
import '../recursos/textos.dart';

/// Estado del envío: eventos pendientes y rechazados, y si la última sincronización fue completa.
///
/// Solo lee el estado de la bandeja de salida; no envía nada por sí misma.
class EstadoEnvioPantalla extends StatelessWidget {
  const EstadoEnvioPantalla({super.key, required this.bandeja});

  final BandejaSalida bandeja;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Textos.estadoEnvio)),
      body: StreamBuilder<void>(
        stream: bandeja.cambios,
        builder: (context, _) {
          final ultima = bandeja.ultimaSincronizacion;
          final estadoUltima = ultima == null
              ? Textos.sinSincronizar
              : ultima.completa
                  ? Textos.ultimaSincronizacionCompleta
                  : Textos.ultimaSincronizacionIncompleta;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Semantics(
                identifier: 'estado.envio.pendientes',
                child: Text(
                  Textos.enviosPendientes(bandeja.pendientes),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                identifier: 'estado.envio.rechazados',
                child: Text(
                  Textos.enviosRechazados(bandeja.rechazados.length),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                identifier: 'estado.envio.ultima',
                child: Text(estadoUltima, style: const TextStyle(fontSize: 18)),
              ),
            ],
          );
        },
      ),
    );
  }
}
