import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: SafeArea(
      child: Scaffold(
        body: Center(child: Text('Contenido lejos del notch')),
      ),
    ),
  ));
}
