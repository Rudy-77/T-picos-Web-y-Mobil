import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(const MaterialApp(
    home: SafeArea(
      child: Scaffold(
        body: Center(child: Text('Contenido lejos del notch')),
      ),
    ),
  ));
  return w;
}
