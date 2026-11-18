import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: Shell()));
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int indice = 0;

  static const pantallas = [
    Center(child: Text('Aquí va la lista de pedidos')),
    Center(child: Text('Aquí va el formulario de alta')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entregas')),
      body: pantallas[indice],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indice,
        onTap: (i) => setState(() => indice = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lista'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Alta'),
        ],
      ),
    );
  }
}
