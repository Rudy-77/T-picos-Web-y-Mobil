import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(const MaterialApp(home: AltaPedido()));
  return w;
}

class AltaPedido extends StatefulWidget {
  const AltaPedido({super.key});

  @override
  State<AltaPedido> createState() => _AltaPedidoState();
}

class _AltaPedidoState extends State<AltaPedido> {
  final distancia = TextEditingController();
  final peso = TextEditingController();

  @override
  void dispose() {
    distancia.dispose();
    peso.dispose();
    super.dispose();
  }

  void _enviar() {
    final d = distancia.text.trim();
    final p = peso.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('distancia=$d peso=$p')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: distancia,
              decoration: const InputDecoration(labelText: 'Distancia (km)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: peso,
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _enviar, child: const Text('Crear')),
          ],
        ),
      ),
    );
  }
}
