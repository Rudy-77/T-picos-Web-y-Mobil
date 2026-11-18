import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Tarjeta')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Card(
          child: ListTile(
            leading: Icon(Icons.local_shipping),
            title: Text('Folio D2757CBE'),
            subtitle: Text('Medio: dron · 12 km'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      ),
    ),
  ));
  return w;
}
