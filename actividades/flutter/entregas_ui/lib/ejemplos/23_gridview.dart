import 'package:flutter/material.dart';

void main() {
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
}
