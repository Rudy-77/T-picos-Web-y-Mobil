import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Menú')),
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(child: Text('Entregas UI')),
            ListTile(leading: Icon(Icons.home), title: Text('Inicio')),
            ListTile(leading: Icon(Icons.settings), title: Text('Ajustes')),
          ],
        ),
      ),
      body: const Center(child: Text('Abran el menú ☰')),
    ),
  ));
}
