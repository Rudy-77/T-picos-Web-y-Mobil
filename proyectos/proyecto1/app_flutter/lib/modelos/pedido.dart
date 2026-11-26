import 'recomendacion.dart';

class Pedido {
  final String folio;
  final DateTime creadoEn;
  final String? producto;
  final int cantidad;
  final Recomendacion resultado;

  const Pedido({
    required this.folio,
    required this.creadoEn,
    required this.producto,
    required this.cantidad,
    required this.resultado,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
    folio: json['folio'] as String,
    creadoEn: DateTime.parse(json['creado_en'] as String).toLocal(),
    producto: (json['producto'] as Map<String, dynamic>?)?['nombre'] as String?,
    cantidad: json['cantidad'] as int,
    resultado: Recomendacion.fromJson(json['resultado'] as Map<String, dynamic>),
  );
}
