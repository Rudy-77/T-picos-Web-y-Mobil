import 'package:flutter/material.dart';

Future<List<String>> cargarFolios() async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return ['D2757CBE', 'A1B2C3D4'];
}

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('FutureBuilder')),
      body: FutureBuilder<List<String>>(
        future: cargarFolios(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final datos = snap.data!;
          return ListView(
            children: [for (final f in datos) ListTile(title: Text(f))],
          );
        },
      ),
    ),
  ));
  return w;
}
