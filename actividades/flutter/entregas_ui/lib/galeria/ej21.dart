import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(const MaterialApp(home: PostPedido()));
  return w;
}

class PostPedido extends StatefulWidget {
  const PostPedido({super.key});

  @override
  State<PostPedido> createState() => _PostPedidoState();
}

class _PostPedidoState extends State<PostPedido> {
  String mensaje = 'Sin enviar';
  bool cargando = false;

  Future<void> _crear() async {
    setState(() {
      cargando = true;
      mensaje = 'Enviando…';
    });
    try {
      final url = Uri.parse('http://127.0.0.1:8080/pedidos');
      final r = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'distancia_km': 12,
          'peso_kg': 1.5,
        }),
      );
      setState(() => mensaje = '${r.statusCode}: ${r.body}');
    } catch (e) {
      setState(() => mensaje = 'Fallo de red: $e');
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HTTP POST')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: cargando ? null : _crear,
              child: const Text('POST /pedidos'),
            ),
            const SizedBox(height: 16),
            if (cargando) const LinearProgressIndicator(),
            Text(mensaje),
          ],
        ),
      ),
    );
  }
}
