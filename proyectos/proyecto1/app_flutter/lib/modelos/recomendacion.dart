const nombresEnvio = {
  'estandar': 'Estándar',
  'protegido': 'Protegido',
  'humedad': 'Humedad',
  'termico': 'Térmico',
};

String nombreEnvio(String clave) => nombresEnvio[clave] ?? clave;

class OpcionRanking {
  final String envio;
  final double probabilidad;
  final bool posible;

  const OpcionRanking(this.envio, this.probabilidad, this.posible);

  factory OpcionRanking.fromJson(Map<String, dynamic> json) => OpcionRanking(
    json['envio'] as String,
    (json['probabilidad'] as num).toDouble(),
    json['posible'] as bool,
  );
}

class Descarte {
  final String envio;
  final String motivo;

  const Descarte(this.envio, this.motivo);

  factory Descarte.fromJson(Map<String, dynamic> json) =>
      Descarte(json['envio'] as String, json['motivo'] as String);
}

class PlanEnvio {
  final String empaque;
  final int dias;
  final double costoEstimadoMxn;
  final String indicacion;
  final String riegoSugerido;

  const PlanEnvio({
    required this.empaque,
    required this.dias,
    required this.costoEstimadoMxn,
    required this.indicacion,
    required this.riegoSugerido,
  });

  factory PlanEnvio.fromJson(Map<String, dynamic> json) => PlanEnvio(
    empaque: json['empaque'] as String,
    dias: json['dias'] as int,
    costoEstimadoMxn: (json['costo_estimado_mxn'] as num).toDouble(),
    indicacion: json['indicacion'] as String,
    riegoSugerido: json['riego_sugerido'] as String,
  );
}

class Recomendacion {
  final String envio;
  final double confianza;
  final String preferidoPorModelo;
  final bool corregidoPorReglas;
  final bool sinOpcionValida;
  final String motivo;
  final List<OpcionRanking> ranking;
  final List<Descarte> descartados;
  final PlanEnvio plan;

  const Recomendacion({
    required this.envio,
    required this.confianza,
    required this.preferidoPorModelo,
    required this.corregidoPorReglas,
    required this.sinOpcionValida,
    required this.motivo,
    required this.ranking,
    required this.descartados,
    required this.plan,
  });

  factory Recomendacion.fromJson(Map<String, dynamic> json) => Recomendacion(
    envio: json['envio'] as String,
    confianza: (json['confianza'] as num).toDouble(),
    preferidoPorModelo: json['preferido_por_modelo'] as String,
    corregidoPorReglas: json['corregido_por_reglas'] as bool,
    sinOpcionValida: json['sin_opcion_valida'] as bool? ?? false,
    motivo: json['motivo'] as String,
    ranking: (json['ranking'] as List)
        .map((o) => OpcionRanking.fromJson(o as Map<String, dynamic>))
        .toList(),
    descartados: (json['descartados'] as List)
        .map((d) => Descarte.fromJson(d as Map<String, dynamic>))
        .toList(),
    plan: PlanEnvio.fromJson(json['plan'] as Map<String, dynamic>),
  );
}
