import 'package:flutter/material.dart';

class TituloSeccion extends StatelessWidget {
  final String texto;

  const TituloSeccion(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
  );
}

// Limita el ancho del contenido en pantallas grandes (Chrome) y lo centra.
class AnchoMaximo extends StatelessWidget {
  final Widget child;
  final double ancho;

  const AnchoMaximo({super.key, required this.child, this.ancho = 760});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: ancho),
      child: child,
    ),
  );
}

// Animación de los botones: se encogen un poco al presionarlos y regresan al soltar.
// Usa Listener para no quitarle el toque al botón que envuelve.
class Presionable extends StatefulWidget {
  final Widget child;

  const Presionable({super.key, required this.child});

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable> {
  bool _presionado = false;

  void _cambiar(bool valor) {
    if (_presionado != valor) setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _cambiar(true),
    onPointerUp: (_) => _cambiar(false),
    onPointerCancel: (_) => _cambiar(false),
    child: AnimatedScale(
      scale: _presionado ? 0.95 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}
