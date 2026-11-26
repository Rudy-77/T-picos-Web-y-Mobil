import 'producto.dart';

// Deben coincidir con las opciones que acepta el backend.
const tiposPlanta = {
  'suculenta': 'Suculenta',
  'interior_tropical': 'Interior tropical',
  'exterior': 'Exterior',
  'frutal': 'Frutal',
  'hortaliza': 'Hortaliza',
  'helecho': 'Helecho',
};
const epocas = {
  'primavera': 'Primavera',
  'verano': 'Verano',
  'otono': 'Otoño',
  'invierno': 'Invierno',
};
const prioridades = {'normal': 'Normal', 'express': 'Express'};
const zonasDestino = {'urbana': 'Urbana', 'periferia': 'Periferia', 'rural': 'Rural'};

// Las 14 entradas del modelo; el modelo y las reglas corren en el servidor.
class Caracteristicas {
  double distanciaKm;
  double pesoKg;
  double alturaCm;
  double diametroMacetaCm;
  int cantidadPlantas;
  double valorDeclaradoMxn;
  double temperaturaDestinoC;
  int diasEnTransito;
  bool fragil;
  bool raizDesnuda;
  String tipoPlanta;
  String epoca;
  String prioridad;
  String zonaDestino;

  Caracteristicas({
    this.distanciaKm = 25,
    this.pesoKg = 1,
    this.alturaCm = 30,
    this.diametroMacetaCm = 15,
    this.cantidadPlantas = 1,
    this.valorDeclaradoMxn = 300,
    this.temperaturaDestinoC = 20,
    this.diasEnTransito = 1,
    this.fragil = false,
    this.raizDesnuda = false,
    this.tipoPlanta = 'exterior',
    String? epoca,
    this.prioridad = 'normal',
    this.zonaDestino = 'urbana',
  }) : epoca = epoca ?? epocaActual(DateTime.now());

  factory Caracteristicas.desdeProducto(Producto p) => Caracteristicas(
    pesoKg: p.pesoKg,
    alturaCm: p.alturaCm ?? 30,
    diametroMacetaCm: p.diametroMacetaCm ?? 0,
    valorDeclaradoMxn: p.precioMxn,
    fragil: p.fragil,
    raizDesnuda: p.raizDesnuda,
    tipoPlanta: p.tipoPlanta ?? 'exterior',
  );

  Map<String, dynamic> toJson() => {
    'distancia_km': distanciaKm,
    'peso_kg': pesoKg,
    'altura_cm': alturaCm,
    'diametro_maceta_cm': diametroMacetaCm,
    'cantidad_plantas': cantidadPlantas,
    'valor_declarado_mxn': valorDeclaradoMxn,
    'temperatura_destino_c': temperaturaDestinoC,
    'dias_en_transito': diasEnTransito,
    'fragil': fragil,
    'raiz_desnuda': raizDesnuda,
    'tipo_planta': tipoPlanta,
    'epoca': epoca,
    'prioridad': prioridad,
    'zona_destino': zonaDestino,
  };
}

String epocaActual(DateTime fecha) {
  final mes = fecha.month;
  if (mes >= 3 && mes <= 5) return 'primavera';
  if (mes >= 6 && mes <= 8) return 'verano';
  if (mes >= 9 && mes <= 11) return 'otono';
  return 'invierno';
}
