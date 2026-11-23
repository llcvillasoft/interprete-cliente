import 'package:flutter/material.dart';

import '../datos/api_cliente.dart';
import '../dominio/bandeja_salida.dart';
import '../dominio/ventana.dart';
import '../recursos/textos.dart';
import '../tokens.dart';
import 'estado_envio_pantalla.dart';
import 'sesion_pantalla.dart';

/// Hoy: la ventana sostenida de cada dirección y el botón para practicar.
class HoyPantalla extends StatefulWidget {
  const HoyPantalla({super.key, required this.api, required this.bandeja});

  final ApiCliente api;
  final BandejaSalida bandeja;

  @override
  State<HoyPantalla> createState() => _HoyPantallaState();
}

class _HoyPantallaState extends State<HoyPantalla> {
  late final Future<Map<Direccion, Ventana?>> _ventanas = _cargar();

  Future<Map<Direccion, Ventana?>> _cargar() async {
    final ventanas = <Direccion, Ventana?>{};
    for (final direccion in Direccion.values) {
      final niveles = await widget.api.nivelesDe(direccion);
      ventanas[direccion] = ventanaDesde(direccion, niveles);
    }
    return ventanas;
  }

  void _verEstadoEnvio() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EstadoEnvioPantalla(bandeja: widget.bandeja)),
    );
  }

  Future<void> _practicar() async {
    try {
      final sesion = await widget.api.crearSesion();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => SesionPantalla(sesion: sesion)),
      );
    } on ErrorApi catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Textos.noSePudoCrearSesion(error.estado))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<Direccion, Ventana?>>(
      future: _ventanas,
      builder: (context, instantanea) {
        final ventanas = instantanea.data;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(Textos.hoy, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            if (ventanas == null) const LinearProgressIndicator(),
            if (ventanas != null)
              for (final direccion in Direccion.values)
                _TarjetaVentana(direccion: direccion, ventana: ventanas[direccion]),
            const SizedBox(height: 24),
            Semantics(
              identifier: 'hoy.practicar.boton',
              button: true,
              child: FilledButton(
                onPressed: _practicar,
                child: Text(Textos.practicar),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              identifier: 'hoy.estado.envio.boton',
              button: true,
              child: OutlinedButton(
                onPressed: _verEstadoEnvio,
                child: Text(Textos.estadoEnvio),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TarjetaVentana extends StatelessWidget {
  const _TarjetaVentana({required this.direccion, required this.ventana});

  final Direccion direccion;
  final Ventana? ventana;

  @override
  Widget build(BuildContext context) {
    final color = direccion == Direccion.enEs ? Tokens.enEs : Tokens.esEn;
    final actual = ventana;
    final texto = actual == null
        ? Textos.ventanaSinTurnos(direccion.etiqueta)
        : Textos.ventanaDetalle(
            direccion.etiqueta,
            formatoFactor(actual.factor),
            actual.tendencia.texto,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        identifier: 'hoy.ventana.${direccion.identificador}',
        container: true,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Tokens.superficie,
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(texto, style: TextStyle(color: color, fontSize: 18)),
        ),
      ),
    );
  }
}
