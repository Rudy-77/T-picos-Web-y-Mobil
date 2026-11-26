import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../modelos/caracteristicas.dart';
import '../modelos/pedido.dart';
import '../modelos/producto.dart';
import '../modelos/recomendacion.dart';

class ErrorApi implements Exception {
  final String mensaje;

  const ErrorApi(this.mensaje);

  @override
  String toString() => mensaje;
}

// Único lugar de la app que habla HTTP con el backend: las pantallas reciben
// objetos o un ErrorApi. El http.Client se inyecta para probar sin servidor.
class ApiVivero {
  final String baseUrl;
  final http.Client _cliente;

  // Sin la diagonal final: "http://host:8000/" daría rutas "//api/...".
  ApiVivero({String baseUrl = apiBaseUrl, http.Client? cliente})
    : baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
      _cliente = cliente ?? http.Client();

  static const _espera = Duration(seconds: 10);

  Future<List<Producto>> listarProductos({String busqueda = '', String? categoria}) async {
    final parametros = {
      if (busqueda.trim().isNotEmpty) 'q': busqueda.trim(),
      'categoria': ?categoria,
    };
    final url = Uri.parse('$baseUrl/api/productos/')
        .replace(queryParameters: parametros.isEmpty ? null : parametros);
    final datos = await _pedir(() => _cliente.get(url));
    return (datos['productos'] as List)
        .map((p) => Producto.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<Producto> obtenerProducto(int id) async {
    final datos = await _pedir(() => _cliente.get(Uri.parse('$baseUrl/api/productos/$id/')));
    return Producto.fromJson(datos);
  }

  Future<Recomendacion> recomendar(Caracteristicas caracteristicas) async {
    final datos = await _enviar('/api/recomendar/', caracteristicas.toJson());
    return Recomendacion.fromJson(datos['resultado'] as Map<String, dynamic>);
  }

  // No se manda el resultado: el servidor lo vuelve a calcular.
  Future<Pedido> registrarPedido(Caracteristicas caracteristicas, {int? productoId}) async {
    final cuerpo = {
      ...caracteristicas.toJson(),
      'producto_id': ?productoId, // se omite si es null
    };
    return Pedido.fromJson(await _enviar('/api/pedidos/', cuerpo));
  }

  Future<Pedido> buscarPedido(String folio) async {
    final limpio = Uri.encodeComponent(folio.trim().toUpperCase());
    return Pedido.fromJson(
      await _pedir(() => _cliente.get(Uri.parse('$baseUrl/api/pedidos/$limpio/'))),
    );
  }

  Future<Map<String, dynamic>> _enviar(String ruta, Map<String, dynamic> cuerpo) => _pedir(
    () => _cliente.post(
      Uri.parse('$baseUrl$ruta'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(cuerpo),
    ),
  );

  // Convierte cualquier falla (red, tiempo, HTTP 4xx/5xx, JSON inválido) en ErrorApi.
  Future<Map<String, dynamic>> _pedir(Future<http.Response> Function() peticion) async {
    final http.Response respuesta;
    try {
      respuesta = await peticion().timeout(_espera);
    } on TimeoutException {
      throw const ErrorApi('El servidor tardó demasiado en responder.');
    } catch (_) {
      throw ErrorApi('No se pudo conectar con $baseUrl. ¿Está corriendo el servidor Django?');
    }

    Map<String, dynamic> datos;
    try {
      datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ErrorApi('El servidor respondió ${respuesta.statusCode} sin JSON.');
    }

    if (respuesta.statusCode >= 400) {
      final campos = (datos['campos'] as List?)?.join(', ');
      final mensaje = datos['error'] as String? ?? 'Error ${respuesta.statusCode}';
      throw ErrorApi(campos == null ? mensaje : '$mensaje: $campos');
    }
    return datos;
  }
}
