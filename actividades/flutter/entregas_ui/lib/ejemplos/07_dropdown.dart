import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: ElegirMedio()));
}

class ElegirMedio extends StatefulWidget {
  const ElegirMedio({super.key});

  @override
  State<ElegirMedio> createState() => _ElegirMedioState();
}

class _ElegirMedioState extends State<ElegirMedio> {
  String medio = 'moto';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButton<String>(
          value: medio,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'moto', child: Text('Motocicleta')),
            DropdownMenuItem(value: 'dron', child: Text('Dron')),
            DropdownMenuItem(value: 'camioneta', child: Text('Camioneta')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => medio = v);
          },
        ),
      ),
    );
  }
}
