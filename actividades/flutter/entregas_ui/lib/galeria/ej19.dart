import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(MaterialApp(
    // Permite "jalar" con el mouse en Chrome (por defecto solo funciona con touch).
    scrollBehavior: const MaterialScrollBehavior().copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      },
    ),
    home: const ListaRefrescable(),
  ));
  return w;
}

class ListaRefrescable extends StatefulWidget {
  const ListaRefrescable({super.key});

  @override
  State<ListaRefrescable> createState() => _ListaRefrescableState();
}

class _ListaRefrescableState extends State<ListaRefrescable> {
  List<String> folios = ['A111', 'B222'];

  Future<void> _refrescar() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    setState(() {
      folios = [...folios, 'C${folios.length}'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refresh')),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: ListView.builder(
          // Necesario: con pocos elementos la lista no hace scroll y no dispararía el refresh.
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: folios.length,
          itemBuilder: (_, i) => ListTile(title: Text(folios[i])),
        ),
      ),
    );
  }
}
