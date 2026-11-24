import 'package:flutter/material.dart';

import '../modelos/recomendacion.dart';
import '../tema.dart';
import 'estilo.dart';

class PanelRecomendacion extends StatelessWidget {
  final Recomendacion recomendacion;

  const PanelRecomendacion({super.key, required this.recomendacion});

  @override
  Widget build(BuildContext context) {
    final r = recomendacion;
    final tema = Theme.of(context);
    final porcentaje = (r.confianza * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Colores.morado,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Envío recomendado'),
                Text(nombreEnvio(r.envio), style: tema.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Confianza del modelo: $porcentaje %'),
                const SizedBox(height: 8),
                Text(r.motivo),
              ],
            ),
          ),
        ),
        if (r.corregidoPorReglas)
          Card(
            color: tema.colorScheme.tertiaryContainer,
            child: ListTile(
              leading: const Icon(Icons.rule),
              title: Text(
                r.sinOpcionValida
                    ? 'Ningún envío cumple las reglas'
                    : 'Las reglas corrigieron al modelo',
              ),
              subtitle: Text(
                r.sinOpcionValida
                    ? 'Se usa ${nombreEnvio(r.envio)} como respaldo; revisa el pedido con el vivero.'
                    : 'El modelo prefería ${nombreEnvio(r.preferidoPorModelo)}, pero no está permitido.',
              ),
            ),
          ),
        const SizedBox(height: 8),
        const TituloSeccion('Ranking del modelo'),
        for (final opcion in r.ranking)
          ListTile(
            dense: true,
            leading: Icon(
              opcion.posible ? Icons.check_circle : Icons.block,
              color: opcion.posible ? Colores.exito : tema.colorScheme.error,
            ),
            title: Text(nombreEnvio(opcion.envio)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: opcion.probabilidad, minHeight: 6),
              ),
            ),
            trailing: SizedBox(
              width: 64,
              child: Text(
                '${(opcion.probabilidad * 100).toStringAsFixed(1)} %',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        if (r.descartados.isNotEmpty) ...[
          const SizedBox(height: 8),
          const TituloSeccion('Descartados por las reglas'),
          for (final d in r.descartados)
            ListTile(
              dense: true,
              leading: Icon(Icons.close, color: tema.colorScheme.error),
              title: Text(nombreEnvio(d.envio)),
              subtitle: Text(d.motivo),
            ),
        ],
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan de envío', style: tema.textTheme.titleMedium),
                const SizedBox(height: 8),
                _Dato('Empaque', r.plan.empaque),
                _Dato('Días en tránsito', '${r.plan.dias}'),
                _Dato('Costo estimado', '\$${r.plan.costoEstimadoMxn.toStringAsFixed(2)} MXN'),
                _Dato('Indicación', r.plan.indicacion),
                _Dato('Riego sugerido', r.plan.riegoSugerido),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$etiqueta: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: valor),
        ],
      ),
    ),
  );
}
