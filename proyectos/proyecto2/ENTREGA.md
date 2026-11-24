# Entrega · Proyecto 2 (Vivero: asistente del comprador)

Paulo Cesar Perez Martinez, 22121268. Continúa el [Proyecto 1](../proyecto1/ENTREGA.md) (mismo tema, vivero de plantas). Instalación y ejecución en [README.md](README.md); patrones en [ANALISIS_PATRONES.md](ANALISIS_PATRONES.md).

## 1. Nota: enfoque del asistente y por qué no inventa la decisión del recomendador

El asistente es un **clasificador de intenciones** que entrené yo: lee el texto del comprador y devuelve una de 8 intenciones. No genera texto libre. La respuesta sale de plantillas fijas que se rellenan con **datos reales del sistema**: el pedido por folio, el catálogo, la descripción y los límites de cada tipo de envío. El flujo es **pregunta → modelo del asistente → datos del sistema**.

**Por qué no inventa el envío.** Elegir un envío necesita las 14 características de la planta y del destino; un mensaje de texto no las trae, y quien decide es el recomendador del Proyecto 1 (árbol de decisión + reglas del negocio: `envios/recomendador.py`, `envios/reglas.py`). Por eso:
- Con la intención `recomendar_envio`, el asistente **no nombra ningún envío**: explica que lo decide el recomendador y devuelve una `accion` que abre el formulario del Proyecto 1 (`POST /api/recomendar/`). La prueba `test_recomendar_envio_no_elige_un_envio` (`backend/envios/tests/test_asistente.py`) comprueba que la respuesta no trae `envio` ni nombra ninguno de los cuatro.
- Con `explicar_recomendacion`, el asistente **no recalcula**: lee el `resultado` que el Proyecto 1 ya guardó en el pedido (qué prefería el modelo, qué regla lo descartó, el plan). El código del asistente no importa `recomendador.py` ni `servicios.recomendar`.
- Si la confianza del clasificador es menor a **0.40**, responde `no_se` y ofrece lo que sí puede hacer, en lugar de adivinar.

## 2. Dataset y métricas reales

- `ml/datos/asistente_intenciones.csv`: **1 016 frases escritas a mano** (no generadas por plantillas), con variedad: formales e informales, con y sin acentos, con faltas, con y sin folio (103 llevan folio en distintos formatos) y con frases cortas de una palabra. Los folios se cambian por un token antes de vectorizar (`envios/asistente/texto.py`, misma función en entrenamiento y servidor).
- Clases: buscar_producto 186, no_se 173 (17 %), rastreo_folio 132, explicar_recomendacion 127, info_envios 121, recomendar_envio 111, saludo 87, despedida_gracias 79.
- **Cómo creció el corpus.** La primera versión tenía 500 frases. Al probar la app, «¿qué plantas hay en el vivero?» no se contestaba bien, por dos causas: el clasificador la reconocía con poca confianza (0.49) y «¿qué hay en el vivero?» caía en otra intención (0.35), y además la búsqueda trataba «vivero» como si fuera un producto. Amplié el corpus a 1 016 frases (más preguntas generales de catálogo, por categoría, por precio y existencia; más rastreo y explicación con distintos folios; y mucho más `no_se`: temas ajenos, cosas del vivero que el sistema no tiene como pagos, horarios o cancelaciones, preguntas de cuidado de plantas, intentos de abuso y ruido) y arreglé la búsqueda del asistente (ver `buscar_productos` en `envios/asistente/asistente.py`).
- Modelo (`ml/entrenar_asistente.py`): `FeatureUnion` de `TfidfVectorizer` de palabras (1-2 gramas) y de caracteres (2-4) + `LogisticRegression(C=10)`. No cambié el modelo ni sus parámetros en esta ampliación; `C=10` y los n-gramas de caracteres se habían elegido antes con validación cruzada (con el corpus de 500 frases).
- **Partición 75/25** (`stratify`, `random_state=42`; 762 de entrenamiento, 254 de prueba): **exactitud 0.906** (con 500 frases era 0.848).

| Intención | Precisión | Recall | F1 | Soporte |
|---|---|---|---|---|
| buscar_producto | 0.90 | 0.93 | 0.91 | 46 |
| despedida_gracias | 1.00 | 0.65 | 0.79 | 20 |
| explicar_recomendacion | 1.00 | 1.00 | 1.00 | 32 |
| info_envios | 0.97 | 0.97 | 0.97 | 30 |
| no_se | 0.76 | 0.91 | 0.83 | 43 |
| rastreo_folio | 0.97 | 0.94 | 0.95 | 33 |
| recomendar_envio | 0.93 | 0.89 | 0.91 | 28 |
| saludo | 0.86 | 0.82 | 0.84 | 22 |

- **89 frases nuevas** (`ml/datos/asistente_prueba.csv`, ninguna repetida en el dataset; antes eran 42): exactitud **0.955** con el modelo final (0.944 con el modelo entrenado solo con el 75 %). Errores del modelo final: «explícame la teoría de la relatividad» → explicar_recomendacion (0.43); «¿qué planta me sirve para un lugar sin sol?» → recomendar_envio (0.43); «¿qué servicios me ofreces?» → no_se (0.32, bajo el umbral); «quiero cambiar mi pedido de fecha» → rastreo_folio (0.73).
- **Lectura honesta.** Las 89 frases las escribí yo, así que pueden compartir mi estilo con el dataset, y son pocas (un acierto mueve 1.1 puntos); la cifra más prudente es la de la partición, cerca de 0.91. Lo más débil es `despedida_gracias` (recall 0.65, se confunde con saludo y con `no_se` en frases muy cortas como «ok») y la precisión de `no_se` (0.76), que absorbe frases que el modelo no reconoce: es el error que prefiero, porque el asistente responde que no sabe en vez de inventar.
- **Generalización de la pregunta que falló.** «¿qué plantas hay en el vivero?» ya está en el entrenamiento, así que no prueba nada por sí sola. Con redacciones que no están en el corpus («¿qué clase de plantas venden en el vivero?», «¿hay muchas plantas en el vivero?», «¿qué plantitas manejan?», «¿me dices qué plantas tienes?», «¿con qué productos cuenta el vivero?», «¿qué hay para comprar?», «¿venden cosas para jardín?») el clasificador dio `buscar_producto` en las siete, con confianza de 0.67 a 0.99.

## 3. Umbral de confianza: 0.40

Bajo el umbral, la pregunta se contesta como `no_se`. Medido con validación cruzada sobre el entrenamiento y sobre las 89 frases nuevas:

| Umbral | Responde (validación cruzada) | Acierto de lo que responde | Responde (89 frases) | Acierto de lo que responde | Exactitud final (89 frases) |
|---|---|---|---|---|---|
| 0.30 | 99.7 % | 86.3 % | 98.9 % | 95.5 % | 95.5 % |
| **0.40** | 93.8 % | 89.1 % | 96.6 % | 96.5 % | 95.5 % |
| 0.50 | 86.6 % | 92.6 % | 93.3 % | 98.8 % | 95.5 % |
| 0.60 | 77.3 % | 94.9 % | 88.8 % | 98.7 % | 91.0 % |

Mantuve **0.40**: con el corpus nuevo sigue siendo un punto medio razonable (responde 94 % de las preguntas con 89 % de acierto en validación cruzada) y a 0.60 la exactitud final ya baja porque se rechazan preguntas válidas. Está en `UMBRAL_CONFIANZA` de `backend/envios/asistente/asistente.py`.

## 4. Pruebas reales del endpoint

Resultados reales de `curl` con el servidor corriendo (`python manage.py runserver`); el pedido se registró antes con el caso de corrección del Proyecto 1 (`ml/ejemplos/caso_correccion.json`, folio `VIV-20261123-0001`). Se muestra `intencion`, `confianza` y `respuesta`.

| Mensaje | Intención (confianza) | Respuesta |
|---|---|---|
| hola, buenas tardes | saludo (0.996) | ¡Hola! Soy el asistente del vivero. Puedo rastrear tu pedido con su folio, explicarte por qué te salió un envío, buscar productos del catálogo y contarte cómo son los tipos de envío. |
| ¿cómo va mi pedido viv-20261123-0001? | rastreo_folio (0.998) | Encontré el pedido VIV-20261123-0001, registrado el 2026-11-23. Va en envío térmico: caja de unicel con gel térmico, 3 día(s) estimados, costo estimado 442.00 MXN. El sistema guarda el pedido, pero no tiene seguimiento de paquetería. |
| ¿por qué me salió ese envío en el pedido VIV-20261123-0001? | explicar_recomendacion (0.98) | Tu pedido VIV-20261123-0001 salió en envío térmico. El modelo prefería humedad, pero las reglas del vivero lo descartaron porque la planta mide 150.0 cm y el empaque admite hasta 120 cm. Por eso se pasó al siguiente envío posible; el modelo le daba una confianza de 1%. Riego: Regar 24 h antes de empacar; al llegar, rociar las hojas y regar si el sustrato está seco. |
| ¿tienen helechos? | buscar_producto (0.964) | Encontré 1 producto(s) del catálogo. (`productos`: Helecho de Boston) |
| ¿que plantas hay en el vivero? | buscar_producto (0.993) | Tenemos 14 plantas en el catálogo: Aguacate Hass injertado, Aloe vera, Calathea orbifolia, Charola de lechuga romana, Charola de plántulas de jitomate, Echeveria elegans, Ficus lyrata (1.5 m), Haworthia cebra, Helecho de Boston, Lavanda, Limonero enano, Monstera deliciosa, Pothos dorado, Rosal miniatura a raíz desnuda. Te muestro 5 aquí; el resto está en el catálogo. |
| ¿qué hay en el vivero? | buscar_producto (0.934) | Tenemos 20 productos en el catálogo: 14 plantas, 2 macetas, 2 sustratos, 2 fertilizantes. Pregúntame por una categoría o por un nombre. Te muestro 5 aquí; el resto está en el catálogo. |
| ¿qué envío me recomiendas para mandar un cactus? | recomendar_envio (0.989) | El tipo de envío lo decide el recomendador del vivero con los datos de tu planta y del destino; yo no lo elijo. Abre el formulario de nuevo envío para calcularlo. (`accion`: abrir_formulario_envio) |
| ¿qué diferencia hay entre protegido y humedad? | info_envios (0.949) | Protegido: caja reforzada con relleno y tutor para el tallo, para plantas frágiles o altas. Límites: temperatura mínima de destino: 0 °C; temperatura máxima de destino: 38 °C. Humedad: bolsa con sustrato húmedo o musgo dentro de caja ventilada, para raíz desnuda, helechos y tropicales. Límites: temperatura mínima de destino: 3 °C; plantas de hasta 120 cm. |
| ¿cuál es la capital de Francia? | no_se (0.91) | No estoy seguro de haberte entendido o no tengo esa información. Puedo rastrear tu pedido con su folio, explicarte por qué te salió un envío, buscar productos del catálogo y contarte cómo son los tipos de envío. |
| estado del pedido VIV-20200101-0001 | rastreo_folio (0.979) | No encontré un pedido con el folio VIV-20200101-0001. Revisa que esté completo. |

Errores: mensaje vacío → 400 `{"error": "falta el mensaje", "campos": ["mensaje"]}`; `GET /api/asistente/` → 405 `{"error": "método no permitido; usa POST"}`.

Pruebas automáticas: `python manage.py test` → 68 pruebas (28 del Proyecto 1 + 40 del asistente); `flutter test` → 15 (8 + 7 del chat); `flutter analyze` sin problemas.

## 5. Capturas del chat

Tomadas en Chrome con la app web contra el backend de esta carpeta (en `capturas/`). Antes registré un pedido (el ficus del caso de corrección, folio `VIV-20261123-0001`) y escribí los mensajes en el chat; las respuestas son las reales del servidor.

| Captura | Archivo | Mensaje |
|---|---|---|
| Saludo | `capturas/chat_01_saludo.jpg` | hola, buenas tardes |
| Consulta con folio | `capturas/chat_02_consulta_con_folio.jpg` | ¿cómo va mi pedido VIV-20261123-0001? (resumen del pedido) |
| Pregunta del dominio | `capturas/chat_03_pregunta_del_dominio.jpg` | ¿por qué me salió ese envío? (sin repetir el folio: usa el último que recordó el chat) |
| Fuera de dominio | `capturas/chat_04_fuera_de_dominio.jpg` | ¿cuál es la capital de Francia? |
| Extra: productos | `capturas/chat_05_productos.jpg` | ¿tienen helechos? (tarjeta que abre el detalle) |
| Extra: catálogo general | `capturas/chat_08_catalogo_general.jpg` | ¿qué plantas hay en el vivero? (lista las 14 plantas por nombre y muestra 5 tarjetas) |
| Extra: remite al recomendador | `capturas/chat_06_recomendar_envio_remite.jpg` | ¿qué envío me recomiendas para mandar un cactus? (botón al formulario, sin elegir envío) |
| Extra: error de red | `capturas/chat_07_error_de_red.jpg` | con el servidor detenido: mensaje y botón «Reintentar» |

Para repetirlas: levanta el backend (`python manage.py runserver`), abre la app (`flutter run -d chrome`), registra un pedido (catálogo → *Ficus lyrata (1.5 m)* → «Calcular envío» → distancia 320, días en tránsito 3 → «Recomendar envío» → «Registrar pedido») y entra al chat con el ícono de burbuja de la barra del catálogo.

Observación de uso en web: después de enviar con Enter, el campo de texto pierde el foco y hay que hacer clic de nuevo para escribir el siguiente mensaje (el botón de enviar no tiene ese problema). No lo pude corregir de forma verificable.

## 6. Entregables

| Entregable | Dónde |
|---|---|
| Código actualizado, backend | `backend/envios/asistente/`, `views.py`, `urls.py`, `tipos_envio.py` |
| Código actualizado, Flutter | `app_flutter/lib/pantallas/chat.dart`, `lib/modelos/`, `lib/servicios/api_vivero.dart` |
| Dataset y script de entrenamiento | `ml/datos/asistente_intenciones.csv`, `ml/entrenar_asistente.py` |
| Artefacto del modelo | `backend/envios/modelo/modelo_asistente.joblib`; se regenera con `python ml/entrenar_asistente.py` |
| Capturas | `capturas/chat_01` a `chat_08` (sección 5) |
| Nota breve | sección 1 de este archivo |
| Análisis de patrones | [ANALISIS_PATRONES.md](ANALISIS_PATRONES.md) |
