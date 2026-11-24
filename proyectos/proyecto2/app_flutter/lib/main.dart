import 'package:flutter/material.dart';

import 'pantallas/catalogo.dart';
import 'servicios/api_vivero.dart';
import 'tema.dart';

void main() {
  runApp(AppVivero(api: ApiVivero()));
}

class AppVivero extends StatelessWidget {
  final ApiVivero api;
  final ThemeData? tema;

  const AppVivero({super.key, required this.api, this.tema});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vivero',
      debugShowCheckedModeBanner: false,
      theme: tema ?? temaVivero(),
      home: PantallaCatalogo(api: api),
    );
  }
}
