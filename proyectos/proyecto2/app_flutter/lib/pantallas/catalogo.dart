import 'package:flutter/material.dart';

import '../modelos/caracteristicas.dart';
import '../modelos/producto.dart';
import '../servicios/api_vivero.dart';
import '../tema.dart';
import '../widgets/estados.dart';
import '../widgets/estilo.dart';
import 'chat.dart';
import 'consulta_folio.dart';
import 'detalle_producto.dart';
import 'formulario_envio.dart';

// Uso las mismas claves que CATEGORIAS en backend/envios/models.py; null es todas.
const categorias = <String?, String>{
  null: 'Todos',
  'planta': 'Plantas',
  'maceta': 'Macetas',
  'sustrato': 'Sustratos',
  'fertilizante': 'Fertilizantes',
};

class PantallaCatalogo extends StatefulWidget {
  final ApiVivero api;

  const PantallaCatalogo({super.key, required this.api});

  @override
  State<PantallaCatalogo> createState() => _PantallaCatalogoState();
}

class _PantallaCatalogoState extends State<PantallaCatalogo> {
  final _busqueda = TextEditingController();
  String? _categoria;
  late Future<List<Producto>> _productos;

  @override
  void initState() {
    super.initState();
    _productos = widget.api.listarProductos();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _buscar() {
    setState(() {
      _productos = widget.api.listarProductos(busqueda: _busqueda.text, categoria: _categoria);
    });
  }

  void _elegirCategoria(String? categoria) {
    _categoria = categoria;
    _buscar();
  }

  void _abrir(Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vivero'),
        actions: [
          IconButton(
            tooltip: 'Asistente',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => _abrir(PantallaChat(api: widget.api)),
          ),
          IconButton(
            tooltip: 'Consultar folio',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => _abrir(PantallaConsultaFolio(api: widget.api)),
          ),
        ],
      ),
      floatingActionButton: Presionable(
        child: FloatingActionButton.extended(
          onPressed: () =>
              _abrir(PantallaFormularioEnvio(api: widget.api, inicial: Caracteristicas())),
          icon: const Icon(Icons.local_shipping),
          label: const Text('Nuevo envío'),
        ),
      ),
      body: AnchoMaximo(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _busqueda,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _buscar(),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o tipo',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _buscar),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final opcion in categorias.entries)
                      Presionable(
                        child: ChoiceChip(
                          label: Text(opcion.value),
                          selected: _categoria == opcion.key,
                          onSelected: (_) => _elegirCategoria(opcion.key),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Producto>>(
                future: _productos,
                builder: (context, estado) {
                  if (estado.connectionState != ConnectionState.done) {
                    return const Cargando(texto: 'Cargando catálogo...');
                  }
                  if (estado.hasError) {
                    return VistaError(error: estado.error!, alReintentar: _buscar);
                  }
                  final productos = estado.data!;
                  if (productos.isEmpty) {
                    return const VistaVacia('No hay productos que coincidan con la búsqueda.');
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: productos.length,
                    itemBuilder: (context, i) {
                      final p = productos[i];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: Icon(_iconoCategoria(p.categoria)),
                          title: Text(p.nombre),
                          subtitle: Text(
                            [
                              p.categoria,
                              if (p.tipoPlanta != null) tiposPlanta[p.tipoPlanta] ?? p.tipoPlanta!,
                            ].join(' · '),
                            style: const TextStyle(color: Colores.textoTenue),
                          ),
                          trailing: Text('\$${p.precioMxn.toStringAsFixed(2)}'),
                          onTap: () =>
                              _abrir(PantallaDetalleProducto(api: widget.api, productoId: p.id)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconoCategoria(String categoria) => switch (categoria) {
  'planta' => Icons.local_florist,
  'maceta' => Icons.inventory_2,
  'sustrato' => Icons.landscape,
  'fertilizante' => Icons.science,
  _ => Icons.category,
};
