import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vivero_app/modelos/caracteristicas.dart';
import 'package:vivero_app/pantallas/chat.dart';
import 'package:vivero_app/pantallas/detalle_producto.dart';
import 'package:vivero_app/pantallas/formulario_envio.dart';
import 'package:vivero_app/servicios/api_vivero.dart';

import 'widget_test.dart' show json, productoLavanda, resultadoCorregido, temaSinRed;

const folio = 'VIV-20261123-0001';

const respuestaPedido = {
  'intencion': 'rastreo_folio',
  'confianza': 0.98,
  'respuesta': 'Encontré el pedido VIV-20261123-0001, registrado el 2026-11-23.',
  'folio': folio,
  'pedido': {
    'folio': folio,
    'creado_en': '2026-11-23T10:00:00-06:00',
    'producto': 'Lavanda',
    'cantidad': 2,
    'envio': 'termico',
    'corregido_por_reglas': true,
    'plan': {
      'empaque': 'caja de unicel con gel térmico',
      'dias': 3,
      'costo_estimado_mxn': 442.0,
      'riego_sugerido': 'Regar 24 h antes de empacar.',
    },
  },
};

Map<String, dynamic> simple(String intencion, String respuesta, [Map<String, dynamic> extra = const {}]) => {
  'intencion': intencion,
  'confianza': 0.9,
  'respuesta': respuesta,
  ...extra,
};

Future<void> abrirChat(WidgetTester tester, ApiVivero api) =>
    tester.pumpWidget(MaterialApp(theme: temaSinRed, home: PantallaChat(api: api)));

Future<void> escribir(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el chat manda el mensaje al servidor y muestra la respuesta con el resumen del pedido', (
    tester,
  ) async {
    late Map<String, dynamic> cuerpo;
    final api = ApiVivero(
      cliente: MockClient((peticion) async {
        expect(peticion.url.path, '/api/asistente/');
        cuerpo = jsonDecode(peticion.body) as Map<String, dynamic>;
        return json(respuestaPedido);
      }),
    );

    await abrirChat(tester, api);
    await escribir(tester, 'estado de $folio');

    expect(cuerpo['mensaje'], 'estado de $folio');
    expect(cuerpo.containsKey('contexto'), isFalse);
    expect(find.text('estado de $folio'), findsOneWidget);
    expect(find.textContaining('Encontré el pedido'), findsOneWidget);
    expect(find.text('Envío: Térmico (corregido por las reglas)'), findsOneWidget);
    expect(api.ultimoFolio.value, folio);
    expect(find.text('Ver productos'), findsNothing);
  });

  testWidgets('el chat manda el último folio como contexto', (tester) async {
    late Map<String, dynamic> cuerpo;
    final api = ApiVivero(
      cliente: MockClient((peticion) async {
        cuerpo = jsonDecode(peticion.body) as Map<String, dynamic>;
        return json(simple('explicar_recomendacion', 'Explicación.'));
      }),
    );
    api.ultimoFolio.value = folio;

    await abrirChat(tester, api);
    await escribir(tester, '¿por qué me salió ese envío?');

    expect(cuerpo['contexto'], {'ultimo_folio': folio});
  });

  testWidgets('una sugerencia rápida se envía como mensaje', (tester) async {
    late Map<String, dynamic> cuerpo;
    final api = ApiVivero(
      cliente: MockClient((peticion) async {
        cuerpo = jsonDecode(peticion.body) as Map<String, dynamic>;
        return json(simple('buscar_producto', 'Sin resultados.'));
      }),
    );

    await abrirChat(tester, api);
    await tester.tap(find.text('Ver productos'));
    await tester.pumpAndSettle();

    expect(cuerpo['mensaje'], 'Ver productos');
  });

  testWidgets('los productos del asistente abren el detalle del catálogo', (tester) async {
    final api = ApiVivero(
      cliente: MockClient((peticion) async {
        if (peticion.url.path == '/api/productos/9/') return json(productoLavanda);
        return json(simple('buscar_producto', 'Encontré 1 producto(s).', {
          'productos': [productoLavanda],
        }));
      }),
    );

    await abrirChat(tester, api);
    await escribir(tester, '¿tienen lavanda?');
    expect(find.text('Lavanda'), findsOneWidget);

    await tester.tap(find.text('Lavanda'));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaDetalleProducto), findsOneWidget);
  });

  testWidgets('recomendar envío no muestra un envío, solo el botón al formulario', (tester) async {
    final api = ApiVivero(
      cliente: MockClient((_) async => json(simple(
        'recomendar_envio',
        'El tipo de envío lo decide el recomendador del vivero.',
        {'accion': {'tipo': 'abrir_formulario_envio', 'endpoint': '/api/recomendar/'}},
      ))),
    );

    await abrirChat(tester, api);
    await escribir(tester, '¿cómo mando un cactus?');
    expect(find.textContaining('Envío:'), findsNothing);

    await tester.tap(find.text('Abrir formulario de envío'));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaFormularioEnvio), findsOneWidget);
  });

  testWidgets('un error de red se muestra en el chat y se puede reintentar', (tester) async {
    var intentos = 0;
    final api = ApiVivero(
      cliente: MockClient((_) async {
        intentos++;
        if (intentos == 1) throw http.ClientException('sin red');
        return json(simple('saludo', '¡Hola! Soy el asistente.'));
      }),
    );

    await abrirChat(tester, api);
    await escribir(tester, 'hola');
    expect(find.textContaining('No se pudo conectar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('¡Hola! Soy el asistente.'), findsOneWidget);
    expect(find.textContaining('No se pudo conectar'), findsNothing);
    expect(find.text('hola'), findsOneWidget);
  });

  testWidgets('registrar un pedido deja su folio para el chat', (tester) async {
    final api = ApiVivero(
      cliente: MockClient((_) async => json({
        'folio': folio,
        'creado_en': '2026-11-23T10:00:00-06:00',
        'producto': null,
        'cantidad': 1,
        'entradas': <String, dynamic>{},
        'resultado': resultadoCorregido,
      }, 201)),
    );
    expect(api.ultimoFolio.value, isNull);

    await api.registrarPedido(Caracteristicas());
    expect(api.ultimoFolio.value, folio);
  });
}
