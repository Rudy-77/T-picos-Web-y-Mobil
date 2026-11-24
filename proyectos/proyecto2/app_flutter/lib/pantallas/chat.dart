import 'package:flutter/material.dart';

import '../modelos/caracteristicas.dart';
import '../modelos/mensaje_chat.dart';
import '../modelos/producto.dart';
import '../modelos/recomendacion.dart';
import '../modelos/respuesta_asistente.dart';
import '../servicios/api_vivero.dart';
import '../tema.dart';
import '../widgets/estilo.dart';
import 'detalle_producto.dart';
import 'formulario_envio.dart';

const sugerencias = ['Rastrear mi pedido', 'Ver productos', '¿Cómo se manda una planta?'];

class PantallaChat extends StatefulWidget {
  final ApiVivero api;

  const PantallaChat({super.key, required this.api});

  @override
  State<PantallaChat> createState() => _PantallaChatState();
}

class _PantallaChatState extends State<PantallaChat> {
  final _texto = TextEditingController();
  final _lista = ScrollController();
  final _mensajes = <MensajeChat>[
    MensajeChat.aviso(
      'Hola, soy el asistente del vivero. Pregúntame por tu pedido, por los productos '
      'o por los tipos de envío.',
    ),
  ];
  bool _esperando = false;

  @override
  void dispose() {
    _texto.dispose();
    _lista.dispose();
    super.dispose();
  }

  void _enviar(String texto) {
    final pregunta = texto.trim();
    if (pregunta.isEmpty || _esperando) return;
    _texto.clear();
    setState(() {
      _mensajes.add(MensajeChat.delComprador(pregunta));
    });
    _preguntar(pregunta);
  }

  Future<void> _preguntar(String pregunta) async {
    setState(() {
      _esperando = true;
    });
    _bajar();
    try {
      final respuesta = await widget.api.preguntar(
        pregunta,
        ultimoFolio: widget.api.ultimoFolio.value,
      );
      if (!mounted) return;
      // Solo recuerdo un folio que existe: el servidor devolvió su pedido.
      if (respuesta.pedido != null) widget.api.ultimoFolio.value = respuesta.pedido!.folio;
      setState(() {
        _mensajes.add(MensajeChat.delAsistente(respuesta));
        _esperando = false;
      });
    } on ErrorApi catch (error) {
      if (!mounted) return;
      setState(() {
        _mensajes.add(MensajeChat.error('$error', pregunta));
        _esperando = false;
      });
    }
    _bajar();
  }

  void _reintentar(MensajeChat error) {
    setState(() {
      _mensajes.remove(error);
    });
    _preguntar(error.preguntaFallida!);
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lista.hasClients) {
        _lista.animateTo(
          _lista.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _abrir(Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final soloBienvenida = _mensajes.length == 1;
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente')),
      body: AnchoMaximo(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _lista,
                padding: const EdgeInsets.all(16),
                itemCount: _mensajes.length + (_esperando ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _mensajes.length) return const _Escribiendo();
                  final mensaje = _mensajes[i];
                  return _Burbuja(
                    mensaje: mensaje,
                    alReintentar: mensaje.esError ? () => _reintentar(mensaje) : null,
                    alAbrirProducto: (p) =>
                        _abrir(PantallaDetalleProducto(api: widget.api, productoId: p.id)),
                    alAbrirFormulario: () =>
                        _abrir(PantallaFormularioEnvio(api: widget.api, inicial: Caracteristicas())),
                  );
                },
              ),
            ),
            if (soloBienvenida)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sugerencia in sugerencias)
                        Presionable(
                          child: ActionChip(
                            label: Text(sugerencia),
                            onPressed: () => _enviar(sugerencia),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _texto,
                textInputAction: TextInputAction.send,
                onSubmitted: _enviar,
                decoration: InputDecoration(
                  hintText: 'Escribe tu pregunta',
                  suffixIcon: IconButton(
                    tooltip: 'Enviar',
                    icon: const Icon(Icons.send),
                    onPressed: () => _enviar(_texto.text),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  final MensajeChat mensaje;
  final VoidCallback? alReintentar;
  final void Function(Producto) alAbrirProducto;
  final VoidCallback alAbrirFormulario;

  const _Burbuja({
    required this.mensaje,
    required this.alReintentar,
    required this.alAbrirProducto,
    required this.alAbrirFormulario,
  });

  @override
  Widget build(BuildContext context) {
    final respuesta = mensaje.respuesta;
    return Align(
      alignment: mensaje.delComprador ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mensaje.delComprador ? Colores.morado : Colores.superficie,
                borderRadius: BorderRadius.circular(14),
                border: mensaje.esError ? Border.all(color: Colores.error) : null,
              ),
              child: Text(mensaje.texto),
            ),
            if (alReintentar != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Presionable(
                  child: OutlinedButton.icon(
                    onPressed: alReintentar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ),
              ),
            if (respuesta != null) ...[
              for (final producto in respuesta.productos)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    title: Text(producto.nombre),
                    subtitle: Text(
                      producto.categoria,
                      style: const TextStyle(color: Colores.textoTenue),
                    ),
                    trailing: Text('\$${producto.precioMxn.toStringAsFixed(2)}'),
                    onTap: () => alAbrirProducto(producto),
                  ),
                ),
              if (respuesta.pedido != null) _ResumenDelPedido(pedido: respuesta.pedido!),
              if (respuesta.abreFormularioEnvio)
                Presionable(
                  child: FilledButton.icon(
                    onPressed: alAbrirFormulario,
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Abrir formulario de envío'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResumenDelPedido extends StatelessWidget {
  final ResumenPedido pedido;

  const _ResumenDelPedido({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pedido.folio, style: tema.textTheme.titleMedium?.copyWith(color: Colores.dorado)),
            const SizedBox(height: 4),
            Text(
              'Envío: ${nombreEnvio(pedido.envio)}'
              '${pedido.corregidoPorReglas ? ' (corregido por las reglas)' : ''}',
            ),
            if (pedido.producto != null) Text('Producto: ${pedido.producto} × ${pedido.cantidad}'),
            Text('${pedido.empaque} · ${pedido.dias} día(s)'),
            Text('Costo estimado: \$${pedido.costoEstimadoMxn.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}

class _Escribiendo extends StatelessWidget {
  const _Escribiendo();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
    ),
  );
}
