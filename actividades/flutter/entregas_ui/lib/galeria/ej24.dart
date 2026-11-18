import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Mapa / foto')),
      body: Center(
        child: Image.network(
          'https://docs.flutter.dev/assets/images/dash/dash-fainting.gif',
          height: 160,
          errorBuilder: (_, __, ___) => const Text('No cargó la imagen'),
        ),
      ),
    ),
  ));
  return w;
}
