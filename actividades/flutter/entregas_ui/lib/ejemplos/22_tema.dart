import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
    ),
    home: Scaffold(
      appBar: AppBar(title: const Text('Tema')),
      body: Center(
        child: FilledButton(
          onPressed: () {},
          child: const Text('Crear pedido'),
        ),
      ),
    ),
  ));
}
