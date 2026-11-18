import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(const MaterialApp(home: FormularioOpciones()));
  return w;
}

class FormularioOpciones extends StatefulWidget {
  const FormularioOpciones({super.key});

  @override
  State<FormularioOpciones> createState() => _FormularioOpcionesState();
}

class _FormularioOpcionesState extends State<FormularioOpciones> {
  bool urgente = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opciones')),
      body: SwitchListTile(
        title: const Text('Envío urgente'),
        value: urgente,
        onChanged: (v) => setState(() => urgente = v),
      ),
    );
  }
}
