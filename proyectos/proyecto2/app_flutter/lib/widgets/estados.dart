import 'package:flutter/material.dart';

import 'estilo.dart';

class Cargando extends StatelessWidget {
  final String texto;

  const Cargando({super.key, this.texto = 'Cargando...'});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [const CircularProgressIndicator(), const SizedBox(height: 12), Text(texto)],
    ),
  );
}

class VistaError extends StatelessWidget {
  final Object error;
  final VoidCallback alReintentar;

  const VistaError({super.key, required this.error, required this.alReintentar});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Presionable(
            child: FilledButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    ),
  );
}

class VistaVacia extends StatelessWidget {
  final String texto;

  const VistaVacia(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(texto, textAlign: TextAlign.center),
    ),
  );
}
