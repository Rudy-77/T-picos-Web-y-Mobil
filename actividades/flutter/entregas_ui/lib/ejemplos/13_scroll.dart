import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Scroll')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            20,
            (i) => ListTile(title: Text('Campo / pedido $i')),
          ),
        ),
      ),
    ),
  ));
}
