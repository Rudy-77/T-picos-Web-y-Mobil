import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: EtiquetaFolio(folio: 'D2757CBE'),
      ),
    ),
  ));
  return w;
}

class EtiquetaFolio extends StatelessWidget {
  const EtiquetaFolio({super.key, required this.folio});

  final String folio;

  @override
  Widget build(BuildContext context) {
    return Text('Folio: $folio');
  }
}
