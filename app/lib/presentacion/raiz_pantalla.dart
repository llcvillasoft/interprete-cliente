import 'package:flutter/material.dart';

import '../datos/api_cliente.dart';
import '../dominio/bandeja_salida.dart';
import '../recursos/textos.dart';
import '../tokens.dart';
import 'ajustes_pantalla.dart';
import 'hoy_pantalla.dart';

const _destinos = <({IconData icono, String etiqueta})>[
  (icono: Icons.mic_none, etiqueta: Textos.practicar),
  (icono: Icons.fact_check_outlined, etiqueta: Textos.revisar),
  (icono: Icons.show_chart, etiqueta: Textos.progreso),
  (icono: Icons.menu_book_outlined, etiqueta: Textos.cuaderno),
  (icono: Icons.person_outline, etiqueta: Textos.perfil),
];

/// Estructura con la navegación adaptable al ancho: barra inferior o riel lateral.
class RaizPantalla extends StatefulWidget {
  const RaizPantalla({super.key, required this.api, required this.bandeja});

  final ApiCliente api;
  final BandejaSalida bandeja;

  @override
  State<RaizPantalla> createState() => _RaizPantallaState();
}

class _RaizPantallaState extends State<RaizPantalla> {
  int _indice = 0;

  void _elegir(int indice) => setState(() => _indice = indice);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = anchoDe(restricciones.maxWidth);
        final contenido = switch (_indice) {
          0 => HoyPantalla(api: widget.api, bandeja: widget.bandeja),
          4 => AjustesPantalla(api: widget.api),
          _ => const Center(child: Text(Textos.vistaPendiente)),
        };

        if (ancho == AnchoPantalla.compacto) {
          return Scaffold(
            body: contenido,
            bottomNavigationBar: Semantics(
              identifier: 'hoy.navegacion.barra',
              label: Textos.navegacionInferior,
              container: true,
              child: NavigationBar(
                selectedIndex: _indice,
                onDestinationSelected: _elegir,
                destinations: [
                  for (final destino in _destinos)
                    NavigationDestination(icon: Icon(destino.icono), label: destino.etiqueta),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              Semantics(
                identifier: 'hoy.navegacion.riel',
                label: Textos.navegacionLateral,
                container: true,
                child: NavigationRail(
                  selectedIndex: _indice,
                  labelType: ancho == AnchoPantalla.amplio
                      ? NavigationRailLabelType.all
                      : NavigationRailLabelType.none,
                  onDestinationSelected: _elegir,
                  destinations: [
                    for (final destino in _destinos)
                      NavigationRailDestination(
                        icon: Icon(destino.icono),
                        label: Text(destino.etiqueta),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: contenido),
            ],
          ),
        );
      },
    );
  }
}
