import 'package:flutter/material.dart';

import '../modelos/caracteristicas.dart';
import '../modelos/producto.dart';
import '../modelos/recomendacion.dart';
import '../servicios/api_vivero.dart';
import '../widgets/estados.dart';
import '../widgets/estilo.dart';
import '../widgets/panel_recomendacion.dart';
import 'confirmacion.dart';

// Solo consulta la recomendación; el pedido se registra al confirmar.
class PantallaResultado extends StatefulWidget {
  final ApiVivero api;
  final Caracteristicas caracteristicas;
  final Producto? producto;

  const PantallaResultado({
    super.key,
    required this.api,
    required this.caracteristicas,
    this.producto,
  });

  @override
  State<PantallaResultado> createState() => _PantallaResultadoState();
}

class _PantallaResultadoState extends State<PantallaResultado> {
  late Future<Recomendacion> _recomendacion;

  @override
  void initState() {
    super.initState();
    _recomendacion = widget.api.recomendar(widget.caracteristicas);
  }

  void _reintentar() => setState(() {
    _recomendacion = widget.api.recomendar(widget.caracteristicas);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recomendación')),
      body: FutureBuilder<Recomendacion>(
        future: _recomendacion,
        builder: (context, estado) {
          if (estado.connectionState != ConnectionState.done) {
            return const Cargando(texto: 'Consultando al recomendador...');
          }
          if (estado.hasError) return VistaError(error: estado.error!, alReintentar: _reintentar);
          return AnchoMaximo(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PanelRecomendacion(recomendacion: estado.data!),
                const SizedBox(height: 16),
                Presionable(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Registrar pedido'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PantallaConfirmacion(
                          api: widget.api,
                          caracteristicas: widget.caracteristicas,
                          producto: widget.producto,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
