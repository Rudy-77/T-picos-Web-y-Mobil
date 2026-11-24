import 'producto.dart';

// Uso solo un resumen del pedido, sin las entradas completas.
class ResumenPedido {
  final String folio;
  final String? producto;
  final int cantidad;
  final String envio;
  final bool corregidoPorReglas;
  final String empaque;
  final int dias;
  final double costoEstimadoMxn;

  const ResumenPedido({
    required this.folio,
    required this.producto,
    required this.cantidad,
    required this.envio,
    required this.corregidoPorReglas,
    required this.empaque,
    required this.dias,
    required this.costoEstimadoMxn,
  });

  factory ResumenPedido.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>;
    return ResumenPedido(
      folio: json['folio'] as String,
      producto: json['producto'] as String?,
      cantidad: json['cantidad'] as int,
      envio: json['envio'] as String,
      corregidoPorReglas: json['corregido_por_reglas'] as bool,
      empaque: plan['empaque'] as String,
      dias: plan['dias'] as int,
      costoEstimadoMxn: (plan['costo_estimado_mxn'] as num).toDouble(),
    );
  }
}

class RespuestaAsistente {
  final String intencion;
  final double confianza;
  final String respuesta;
  final List<Producto> productos;
  final ResumenPedido? pedido;
  final bool abreFormularioEnvio;

  const RespuestaAsistente({
    required this.intencion,
    required this.confianza,
    required this.respuesta,
    this.productos = const [],
    this.pedido,
    this.abreFormularioEnvio = false,
  });

  factory RespuestaAsistente.fromJson(Map<String, dynamic> json) => RespuestaAsistente(
    intencion: json['intencion'] as String,
    confianza: (json['confianza'] as num).toDouble(),
    respuesta: json['respuesta'] as String,
    productos: ((json['productos'] as List?) ?? [])
        .map((p) => Producto.fromJson(p as Map<String, dynamic>))
        .toList(),
    pedido: json['pedido'] == null
        ? null
        : ResumenPedido.fromJson(json['pedido'] as Map<String, dynamic>),
    abreFormularioEnvio:
        (json['accion'] as Map<String, dynamic>?)?['tipo'] == 'abrir_formulario_envio',
  );
}
