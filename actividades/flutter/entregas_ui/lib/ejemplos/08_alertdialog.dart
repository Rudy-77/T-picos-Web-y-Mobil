import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: ConfirmarPedido()));
}

class ConfirmarPedido extends StatelessWidget {
  const ConfirmarPedido({super.key});

  Future<void> _confirmar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear pedido'),
        content: const Text('¿Mandar el POST al gateway?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aquí iría el HTTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _confirmar(context),
          child: const Text('Crear pedido'),
        ),
      ),
    );
  }
}
