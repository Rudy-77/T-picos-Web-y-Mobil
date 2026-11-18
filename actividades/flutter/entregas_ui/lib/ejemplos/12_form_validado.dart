import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: FormValidado()));
}

class FormValidado extends StatefulWidget {
  const FormValidado({super.key});

  @override
  State<FormValidado> createState() => _FormValidadoState();
}

class _FormValidadoState extends State<FormValidado> {
  final _clave = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validación')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _clave,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Distancia (km)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Obligatorio';
                  }
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Número > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_clave.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Formulario OK')),
                    );
                  }
                },
                child: const Text('Validar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
