import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: FormularioOpciones()));
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
