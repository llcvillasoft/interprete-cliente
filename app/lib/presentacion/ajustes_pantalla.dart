import 'package:flutter/material.dart';

import '../datos/api_cliente.dart';
import '../recursos/textos.dart';

/// Ajustes y privacidad: consentimientos en solo lectura, exportación y borrado de la cuenta.
///
/// Cambiar un consentimiento no está aquí todavía: llega con los productores de eventos (F2-09).
class AjustesPantalla extends StatefulWidget {
  const AjustesPantalla({super.key, required this.api});

  final ApiCliente api;

  @override
  State<AjustesPantalla> createState() => _AjustesPantallaState();
}

class _AjustesPantallaState extends State<AjustesPantalla> {
  late final Future<Map<String, bool>> _consentimientos = widget.api.consentimientos();
  String? _mensaje;
  bool _ocupado = false;

  Future<void> _ejecutar(Future<String> Function() operacion) async {
    setState(() {
      _ocupado = true;
      _mensaje = null;
    });
    String mensaje;
    try {
      mensaje = await operacion();
    } on Exception {
      mensaje = Textos.errorAjustes;
    }
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _mensaje = mensaje;
    });
  }

  Future<void> _exportar() => _ejecutar(() async {
        final exportacion = await widget.api.exportar();
        return Textos.exportacionLista(exportacion.flujos);
      });

  Future<void> _borrar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(Textos.borrarCuentaPregunta),
        content: Text(Textos.borrarCuentaAviso),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: Text(Textos.cancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: Text(Textos.confirmarBorrado),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    await _ejecutar(() async {
      final resultado = await widget.api.borrarCuenta();
      return Textos.cuentaBorrada(resultado.sesiones);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Textos.ajustesTitulo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(Textos.consentimientosTitulo, style: Theme.of(context).textTheme.titleMedium),
          FutureBuilder<Map<String, bool>>(
            future: _consentimientos,
            builder: (context, instantanea) {
              if (instantanea.hasError) return Text(Textos.errorAjustes);
              final consentidos = instantanea.data;
              if (consentidos == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (consentidos.isEmpty) return Text(Textos.consentimientosVacios);
              return Column(
                children: [
                  for (final entrada in consentidos.entries)
                    ListTile(
                      title: Text(entrada.key),
                      trailing: Text(entrada.value ? Textos.concedido : Textos.noConcedido),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(Textos.datosTitulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _ocupado ? null : _exportar,
            child: Text(Textos.exportarDatos),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _ocupado ? null : _borrar,
            child: Text(Textos.borrarCuenta),
          ),
          if (_mensaje != null) ...[
            const SizedBox(height: 16),
            Text(_mensaje!),
          ],
        ],
      ),
    );
  }
}
