import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vivero_app/main.dart';
import 'package:vivero_app/modelos/caracteristicas.dart';
import 'package:vivero_app/modelos/recomendacion.dart';
import 'package:vivero_app/pantallas/formulario_envio.dart';
import 'package:vivero_app/servicios/api_vivero.dart';
import 'package:vivero_app/tema.dart';
import 'package:vivero_app/widgets/panel_recomendacion.dart';

// MockClient responde como Django, así que no hace falta el servidor.
http.Response json(Object datos, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(datos)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

// Mismo tema de la app pero con la fuente del sistema: las pruebas no tienen red.
final temaSinRed = temaVivero(fuentesWeb: false);

const productoLavanda = {
  'id': 9,
  'nombre': 'Lavanda',
  'categoria': 'planta',
  'tipo_planta': 'exterior',
  'descripcion': 'Aromática',
  'precio_mxn': 140.0,
  'stock': 22,
  'peso_kg': 1.1,
  'altura_cm': 40.0,
  'diametro_maceta_cm': 15.0,
  'fragil': false,
  'raiz_desnuda': false,
};

const resultadoCorregido = {
  'envio': 'termico',
  'confianza': 0.013,
  'preferido_por_modelo': 'humedad',
  'corregido_por_reglas': true,
  'sin_opcion_valida': false,
  'motivo': 'se descartó humedad porque la planta mide 150.0 cm',
  'ranking': [
    {'envio': 'humedad', 'probabilidad': 0.973, 'posible': false},
    {'envio': 'termico', 'probabilidad': 0.013, 'posible': true},
  ],
  'descartados': [
    {'envio': 'humedad', 'motivo': 'la planta mide 150.0 cm y el empaque admite hasta 120 cm'},
  ],
  'plan': {
    'envio': 'termico',
    'empaque': 'caja de unicel',
    'dias': 3,
    'costo_estimado_mxn': 442.0,
    'indicacion': 'mantener la temperatura',
    'riego_sugerido': 'Regar 24 h antes de empacar.',
  },
};

void main() {
  testWidgets('el catálogo muestra los productos del servidor', (tester) async {
    final api = ApiVivero(
      cliente: MockClient((peticion) async {
        expect(peticion.url.path, '/api/productos/');
        return json({
          'total': 1,
          'productos': [productoLavanda],
        });
      }),
    );

    await tester.pumpWidget(AppVivero(api: api, tema: temaSinRed));
    expect(find.text('Cargando catálogo...'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Lavanda'), findsOneWidget);
    expect(find.text('\$140.00'), findsOneWidget);
  });

  testWidgets('los botones de categoría filtran el catálogo en el servidor', (tester) async {
    final pedidas = <Uri>[];
    final api = ApiVivero(
      cliente: MockClient((peticion) async {
        pedidas.add(peticion.url);
        return json({'total': 0, 'productos': []});
      }),
    );

    await tester.pumpWidget(AppVivero(api: api, tema: temaSinRed));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fertilizantes'));
    await tester.pumpAndSettle();
    expect(pedidas.last.queryParameters['categoria'], 'fertilizante');

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    expect(pedidas.last.queryParameters.containsKey('categoria'), isFalse);
  });

  testWidgets('un error de red muestra el mensaje y el botón de reintento', (tester) async {
    var intentos = 0;
    final api = ApiVivero(
      cliente: MockClient((_) async {
        intentos++;
        if (intentos == 1) throw http.ClientException('sin red');
        return json({
          'total': 1,
          'productos': [productoLavanda],
        });
      }),
    );

    await tester.pumpWidget(AppVivero(api: api, tema: temaSinRed));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo conectar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Lavanda'), findsOneWidget);
  });

  testWidgets('el panel avisa cuando las reglas corrigieron al modelo', (tester) async {
    final recomendacion = Recomendacion.fromJson(resultadoCorregido);
    await tester.pumpWidget(
      MaterialApp(
        theme: temaSinRed,
        home: Scaffold(
          body: SingleChildScrollView(child: PanelRecomendacion(recomendacion: recomendacion)),
        ),
      ),
    );

    expect(find.text('Térmico'), findsWidgets);
    expect(find.text('Las reglas corrigieron al modelo'), findsOneWidget);
    expect(find.textContaining('prefería Humedad'), findsOneWidget);
    expect(find.textContaining('Regar 24 h antes de empacar.', findRichText: true), findsOneWidget);
  });

  test('el error 400 del servidor llega como ErrorApi legible', () async {
    final api = ApiVivero(
      cliente: MockClient(
        (_) async => json({
          'error': 'faltan campos',
          'campos': ['epoca'],
        }, 400),
      ),
    );
    expect(
      () => api.recomendar(Caracteristicas()),
      throwsA(isA<ErrorApi>().having((e) => e.mensaje, 'mensaje', 'faltan campos: epoca')),
    );
  });

  test('las características se mandan con los nombres que espera Django', () {
    final datos = Caracteristicas(fragil: true).toJson();
    expect(datos.keys, hasLength(14));
    expect(datos['fragil'], true);
    expect(datos.containsKey('temperatura_destino_c'), true);
  });

  test('la URL base con diagonal final no duplica la diagonal', () async {
    late Uri pedida;
    final api = ApiVivero(
      baseUrl: 'http://127.0.0.1:8000/',
      cliente: MockClient((peticion) async {
        pedida = peticion.url;
        return json({'total': 0, 'productos': []});
      }),
    );
    await api.listarProductos();
    expect(pedida.toString(), 'http://127.0.0.1:8000/api/productos/');
  });

  testWidgets('raíz desnuda pone el diámetro en 0 y bloquea el campo', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = Caracteristicas(diametroMacetaCm: 30);
    await tester.pumpWidget(
      MaterialApp(
        theme: temaSinRed,
        home: PantallaFormularioEnvio(
          api: ApiVivero(cliente: MockClient((_) async => json({}))),
          inicial: c,
        ),
      ),
    );
    TextField campo() => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('campo_diametro')),
        matching: find.byType(TextField),
      ),
    );
    expect(campo().controller!.text, '30');
    expect(campo().enabled, isTrue);

    await tester.tap(find.text('Raíz desnuda (sin maceta ni tierra)'));
    await tester.pump();
    expect(campo().controller!.text, '0');
    expect(campo().enabled, isFalse);
    expect(c.diametroMacetaCm, 0);

    await tester.tap(find.text('Raíz desnuda (sin maceta ni tierra)'));
    await tester.pump();
    expect(campo().controller!.text, '30');
    expect(campo().enabled, isTrue);
  });
}
