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
            Text('Folio D2757CBE-A1B2C3D4-F00D1234-ZZ99AA-D2757CBE-A1B2C3D4-F00D1234-ZZ99AA-D2757CBE-A1B2C3D4-F00D1234-ZZ99AA'),
            Text('dron'),
          ],
        ),
      ),
    ),
  ));
  return w;
}
