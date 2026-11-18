import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Medios')),
      body: GridView.count(
        crossAxisCount: 2,
        children: const [
          Card(child: Center(child: Text('Moto'))),
          Card(child: Center(child: Text('Dron'))),
          Card(child: Center(child: Text('Camioneta'))),
          Card(child: Center(child: Text('Bici'))),
        ],
      ),
    ),
  ));
  return w;
}
