import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Vacío')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 64),
            SizedBox(height: 12),
            Text('No hay pedidos todavía'),
            SizedBox(height: 12),
            // ElevatedButton… hacia el alta
          ],
        ),
      ),
    ),
  ));
  return w;
}
