import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../modelos/caracteristicas.dart';
import '../modelos/pedido.dart';
import '../modelos/producto.dart';
import '../modelos/recomendacion.dart';
import '../modelos/respuesta_asistente.dart';

class ErrorApi implements Exception {
  final String mensaje;

  const ErrorApi(this.mensaje);

  @override
  String toString() => mensaje;
}

// Este es el único lugar que habla HTTP; inyecto el http.Client para probar sin servidor.
class ApiVivero {
  final String baseUrl;
  final http.Client _cliente;

  // Guardo el folio del último pedido confirmado para mandarlo al chat como contexto.
  final ultimoFolio = ValueNotifier<String?>(null);

  // Quito la diagonal final: "http://host:8000/" daría rutas "//api/...".
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

  // No mando el resultado: el servidor lo vuelve a calcular.
  Future<Pedido> registrarPedido(Caracteristicas caracteristicas, {int? productoId}) async {
    final cuerpo = {
      ...caracteristicas.toJson(),
      'producto_id': ?productoId,
    };
    final pedido = Pedido.fromJson(await _enviar('/api/pedidos/', cuerpo));
    ultimoFolio.value = pedido.folio;
    return pedido;
  }

  Future<Pedido> buscarPedido(String folio) async {
    final limpio = Uri.encodeComponent(folio.trim().toUpperCase());
    return Pedido.fromJson(
      await _pedir(() => _cliente.get(Uri.parse('$baseUrl/api/pedidos/$limpio/'))),
    );
  }

  Future<RespuestaAsistente> preguntar(String mensaje, {String? ultimoFolio}) async {
    final cuerpo = {
      'mensaje': mensaje,
      if (ultimoFolio != null) 'contexto': {'ultimo_folio': ultimoFolio},
    };
    return RespuestaAsistente.fromJson(await _enviar('/api/asistente/', cuerpo));
  }

  Future<Map<String, dynamic>> _enviar(String ruta, Map<String, dynamic> cuerpo) => _pedir(
    () => _cliente.post(
      Uri.parse('$baseUrl$ruta'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(cuerpo),
    ),
  );

  // Convierto cualquier falla (red, tiempo, HTTP 4xx/5xx, JSON inválido) en ErrorApi.
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
