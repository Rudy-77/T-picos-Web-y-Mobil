import 'package:flutter/material.dart';

import '../modelos/pedido.dart';
import '../servicios/api_vivero.dart';
import '../widgets/estados.dart';
import '../widgets/estilo.dart';
import '../widgets/panel_recomendacion.dart';

class PantallaConsultaFolio extends StatefulWidget {
  final ApiVivero api;

  const PantallaConsultaFolio({super.key, required this.api});

  @override
  State<PantallaConsultaFolio> createState() => _PantallaConsultaFolioState();
}

class _PantallaConsultaFolioState extends State<PantallaConsultaFolio> {
  final _folio = TextEditingController();
  Future<Pedido>? _pedido;

  @override
  void dispose() {
    _folio.dispose();
    super.dispose();
  }

  void _buscar() {
    if (_folio.text.trim().isEmpty) return;
    setState(() {
      _pedido = widget.api.buscarPedido(_folio.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultar folio')),
      body: AnchoMaximo(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _folio,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscar(),
              decoration: InputDecoration(
                labelText: 'Folio (VIV-AAAAMMDD-0001)',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _buscar),
              ),
            ),
            const SizedBox(height: 16),
            if (_pedido != null)
              FutureBuilder<Pedido>(
                future: _pedido,
                builder: (context, estado) {
                  if (estado.connectionState != ConnectionState.done) {
                    return const Cargando(texto: 'Buscando...');
                  }
                  if (estado.hasError) {
                    return VistaError(error: estado.error!, alReintentar: _buscar);
                  }
                  final pedido = estado.data!;
                  final fecha = pedido.creadoEn;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(pedido.folio, style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        'Registrado: ${fecha.day}/${fecha.month}/${fecha.year} '
                        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                      ),
                      if (pedido.producto != null)
                        Text('Producto: ${pedido.producto} × ${pedido.cantidad}'),
                      const SizedBox(height: 12),
                      PanelRecomendacion(recomendacion: pedido.resultado),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
