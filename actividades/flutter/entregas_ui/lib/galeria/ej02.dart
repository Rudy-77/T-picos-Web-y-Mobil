import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(child: ContadorSimple()),
    ),
  ));
  return w;
}

class ContadorSimple extends StatefulWidget {
  const ContadorSimple({super.key});

  @override
  State<ContadorSimple> createState() => _ContadorSimpleState();
}

class _ContadorSimpleState extends State<ContadorSimple> {
  int _n = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Pedidos en pantalla: $_n'),
        ElevatedButton(
          onPressed: () => setState(() => _n++),
          child: const Text('Sumar'),
        ),
      ],
    );
  }
}
