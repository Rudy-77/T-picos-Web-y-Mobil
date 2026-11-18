import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(const MaterialApp(home: BuscadorFolios()));
  return w;
}

class BuscadorFolios extends StatefulWidget {
  const BuscadorFolios({super.key});

  @override
  State<BuscadorFolios> createState() => _BuscadorFoliosState();
}

class _BuscadorFoliosState extends State<BuscadorFolios> {
  final todos = const ['D2757CBE', 'A1B2C3D4', 'F00D1234', 'ZZ99AA'];
  String filtro = '';

  @override
  Widget build(BuildContext context) {
    final vistos = todos
        .where((f) => f.toLowerCase().contains(filtro.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Filtrar folio',
                border: OutlineInputBorder(),
              ),
              onChanged: (t) => setState(() => filtro = t),
            ),
          ),
          Expanded(
            child: ListView(
              children: [for (final f in vistos) ListTile(title: Text(f))],
            ),
          ),
        ],
      ),
    );
  }
}
