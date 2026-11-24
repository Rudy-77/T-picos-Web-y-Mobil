import 'package:flutter/material.dart';

import '../modelos/caracteristicas.dart';
import '../modelos/producto.dart';
import '../servicios/api_vivero.dart';
import '../tema.dart';
import '../widgets/estados.dart';
import '../widgets/estilo.dart';
import 'formulario_envio.dart';

class PantallaDetalleProducto extends StatefulWidget {
  final ApiVivero api;
  final int productoId;

  const PantallaDetalleProducto({super.key, required this.api, required this.productoId});

  @override
  State<PantallaDetalleProducto> createState() => _PantallaDetalleProductoState();
}

class _PantallaDetalleProductoState extends State<PantallaDetalleProducto> {
  late Future<Producto> _producto;

  @override
  void initState() {
    super.initState();
    _producto = widget.api.obtenerProducto(widget.productoId);
  }

  void _reintentar() => setState(() {
    _producto = widget.api.obtenerProducto(widget.productoId);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: FutureBuilder<Producto>(
        future: _producto,
        builder: (context, estado) {
          if (estado.connectionState != ConnectionState.done) return const Cargando();
          if (estado.hasError) return VistaError(error: estado.error!, alReintentar: _reintentar);
          return _Contenido(api: widget.api, producto: estado.data!);
        },
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  final ApiVivero api;
  final Producto producto;

  const _Contenido({required this.api, required this.producto});

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final tema = Theme.of(context);
    String medida(double? valor, String unidad) => valor == null ? '—' : '$valor $unidad';

    return AnchoMaximo(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(p.nombre, style: tema.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            [
              p.categoria,
              if (p.tipoPlanta != null) tiposPlanta[p.tipoPlanta] ?? p.tipoPlanta!,
            ].join(' · '),
            style: const TextStyle(color: Colores.textoTenue),
          ),
          const SizedBox(height: 12),
          Text(p.descripcion),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Precio'),
                  trailing: Text('\$${p.precioMxn.toStringAsFixed(2)} MXN'),
                ),
                ListTile(title: const Text('Existencias'), trailing: Text('${p.stock}')),
                ListTile(title: const Text('Peso'), trailing: Text(medida(p.pesoKg, 'kg'))),
                ListTile(title: const Text('Altura'), trailing: Text(medida(p.alturaCm, 'cm'))),
                ListTile(
                  title: const Text('Diámetro de maceta'),
                  trailing: Text(medida(p.diametroMacetaCm, 'cm')),
                ),
                ListTile(title: const Text('Frágil'), trailing: Text(p.fragil ? 'Sí' : 'No')),
                ListTile(
                  title: const Text('Raíz desnuda'),
                  trailing: Text(p.raizDesnuda ? 'Sí' : 'No'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (p.esPlanta)
            Presionable(
              child: FilledButton.icon(
                icon: const Icon(Icons.local_shipping),
                label: const Text('Calcular envío de esta planta'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PantallaFormularioEnvio(
                      api: api,
                      inicial: Caracteristicas.desdeProducto(p),
                      producto: p,
                    ),
                  ),
                ),
              ),
            )
          else
            const Text(
              'El recomendador de envío es para plantas; este artículo viaja como paquete normal.',
            ),
        ],
      ),
    );
  }
}
