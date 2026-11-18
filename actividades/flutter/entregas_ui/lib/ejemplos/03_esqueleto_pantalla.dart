import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Entregas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nuevo pedido'),
            const TextField(
              decoration: InputDecoration(labelText: 'Distancia (km)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: null, // luego: POST al gateway
              child: const Text('Crear pedido'),
            ),
          ],
        ),
      ),
    ),
  ));
}
