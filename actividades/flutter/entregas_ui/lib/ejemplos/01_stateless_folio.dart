import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: EtiquetaFolio(folio: 'D2757CBE'),
      ),
    ),
  ));
}

class EtiquetaFolio extends StatelessWidget {
  const EtiquetaFolio({super.key, required this.folio});

  final String folio;

  @override
  Widget build(BuildContext context) {
    return Text('Folio: $folio');
  }
}
