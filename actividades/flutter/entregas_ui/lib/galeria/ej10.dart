import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(const MaterialApp(home: CargaFalsa()));
  return w;
}

class CargaFalsa extends StatefulWidget {
  const CargaFalsa({super.key});

  @override
  State<CargaFalsa> createState() => _CargaFalsaState();
}

class _CargaFalsaState extends State<CargaFalsa> {
  bool cargando = false;
  String? resultado;

  Future<void> _simular() async {
    setState(() {
      cargando = true;
      resultado = null;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    setState(() {
      cargando = false;
      resultado = 'Folio D2757CBE';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carga')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cargando) const CircularProgressIndicator(),
            if (resultado != null) Text(resultado!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: cargando ? null : _simular,
              child: const Text('Crear (simulado)'),
            ),
          ],
        ),
      ),
    );
  }
}
