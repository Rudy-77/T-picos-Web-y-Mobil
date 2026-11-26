class Producto {
  final int id;
  final String nombre;
  final String categoria;
  final String? tipoPlanta;
  final String descripcion;
  final double precioMxn;
  final int stock;
  final double pesoKg;
  final double? alturaCm;
  final double? diametroMacetaCm;
  final bool fragil;
  final bool raizDesnuda;

  const Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.tipoPlanta,
    required this.descripcion,
    required this.precioMxn,
    required this.stock,
    required this.pesoKg,
    required this.alturaCm,
    required this.diametroMacetaCm,
    required this.fragil,
    required this.raizDesnuda,
  });

  bool get esPlanta => categoria == 'planta';

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    categoria: json['categoria'] as String,
    tipoPlanta: json['tipo_planta'] as String?,
    descripcion: json['descripcion'] as String? ?? '',
    precioMxn: (json['precio_mxn'] as num).toDouble(),
    stock: json['stock'] as int,
    pesoKg: (json['peso_kg'] as num).toDouble(),
    alturaCm: (json['altura_cm'] as num?)?.toDouble(),
    diametroMacetaCm: (json['diametro_maceta_cm'] as num?)?.toDouble(),
    fragil: json['fragil'] as bool,
    raizDesnuda: json['raiz_desnuda'] as bool,
  );
}
