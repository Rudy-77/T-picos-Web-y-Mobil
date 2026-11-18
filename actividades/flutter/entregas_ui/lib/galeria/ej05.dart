import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Resumen')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text('Folio D2757CBE')),
            Text('dron'),
          ],
        ),
      ),
    ),
  ));
  return w;
}
