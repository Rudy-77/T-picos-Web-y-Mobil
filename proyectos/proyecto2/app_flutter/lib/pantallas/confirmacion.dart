import 'package:flutter/material.dart';

import '../modelos/caracteristicas.dart';
import '../modelos/pedido.dart';
import '../modelos/producto.dart';
import '../modelos/recomendacion.dart';
import '../servicios/api_vivero.dart';
import '../tema.dart';
import '../widgets/estados.dart';
import '../widgets/estilo.dart';

class PantallaConfirmacion extends StatefulWidget {
  final ApiVivero api;
  final Caracteristicas caracteristicas;
  final Producto? producto;

  const PantallaConfirmacion({
    super.key,
    required this.api,
    required this.caracteristicas,
    this.producto,
  });

  @override
  State<PantallaConfirmacion> createState() => _PantallaConfirmacionState();
}

class _PantallaConfirmacionState extends State<PantallaConfirmacion> {
  late Future<Pedido> _pedido;

  @override
  void initState() {
    super.initState();
    _pedido = _registrar();
  }

  Future<Pedido> _registrar() =>
      widget.api.registrarPedido(widget.caracteristicas, productoId: widget.producto?.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación'), automaticallyImplyLeading: false),
      body: FutureBuilder<Pedido>(
        future: _pedido,
        builder: (context, estado) {
          if (estado.connectionState != ConnectionState.done) {
            return const Cargando(texto: 'Registrando pedido...');
          }
          if (estado.hasError) {
            return VistaError(
              error: estado.error!,
              // Uso llaves porque setState no acepta una función que devuelva un Future.
              alReintentar: () => setState(() {
                _pedido = _registrar();
              }),
            );
          }
          final pedido = estado.data!;
          final tema = Theme.of(context);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 56, color: Colores.exito),
                    const SizedBox(height: 12),
                    Text('Pedido registrado', style: tema.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    SelectableText(
                      pedido.folio,
                      style: tema.textTheme.headlineSmall?.copyWith(color: Colores.dorado),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Envío: ${nombreEnvio(pedido.resultado.envio)}'
                      '${pedido.resultado.corregidoPorReglas ? ' (corregido por las reglas)' : ''}',
                    ),
                    if (pedido.producto != null)
                      Text('Producto: ${pedido.producto} × ${pedido.cantidad}'),
                    const SizedBox(height: 24),
                    Presionable(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).popUntil((ruta) => ruta.isFirst),
                        child: const Text('Volver al catálogo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
