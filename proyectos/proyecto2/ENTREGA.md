# Entrega · Proyecto 2 (Vivero: asistente del comprador)

Paulo Cesar Perez Martinez, 22121268. Continúa el [Proyecto 1](../proyecto1/ENTREGA.md) (mismo tema, vivero de plantas). Instalación y ejecución en [README.md](README.md); patrones en [ANALISIS_PATRONES.md](ANALISIS_PATRONES.md).

## 1. Nota: enfoque del asistente y por qué no inventa la decisión del recomendador

El asistente es un **clasificador de intenciones** que entrené yo: lee el texto del comprador y devuelve una de 8 intenciones. No genera texto libre. La respuesta sale de plantillas fijas que se rellenan con **datos reales del sistema**: el pedido por folio, el catálogo, la descripción y los límites de cada tipo de envío. El flujo es **pregunta → modelo del asistente → datos del sistema**.

**Por qué no inventa el envío.** Elegir un envío necesita las 14 características de la planta y del destino; un mensaje de texto no las trae, y quien decide es el recomendador del Proyecto 1 (árbol de decisión + reglas del negocio: `envios/recomendador.py`, `envios/reglas.py`). Por eso:
- Con la intención `recomendar_envio`, el asistente **no nombra ningún envío**: explica que lo decide el recomendador y devuelve una `accion` que abre el formulario del Proyecto 1 (`POST /api/recomendar/`). La prueba `test_recomendar_envio_no_elige_un_envio` (`backend/envios/tests/test_asistente.py`) comprueba que la respuesta no trae `envio` ni nombra ninguno de los cuatro.
- Con `explicar_recomendacion`, el asistente **no recalcula**: lee el `resultado` que el Proyecto 1 ya guardó en el pedido (qué prefería el modelo, qué regla lo descartó, el plan). El código del asistente no importa `recomendador.py` ni `servicios.recomendar`.
- Si la confianza del clasificador es menor a **0.40**, responde `no_se` y ofrece lo que sí puede hacer, en lugar de adivinar.

## 2. Dataset y métricas reales

- `ml/datos/asistente_intenciones.csv`: **500 frases escritas a mano** (no generadas por plantillas), con variedad: formales e informales, con y sin acentos, con faltas, con y sin folio (58 llevan folio en distintos formatos). Los folios se cambian por un token antes de vectorizar (`envios/asistente/texto.py`, misma función en entrenamiento y servidor).
- Clases: rastreo_folio 73, buscar_producto 72, no_se 71 (14 %), explicar_recomendacion 70, info_envios 60, recomendar_envio 59, saludo 50, despedida_gracias 45.
- Modelo (`ml/entrenar_asistente.py`): `FeatureUnion` de `TfidfVectorizer` de palabras (1-2 gramas) y de caracteres (2-4) + `LogisticRegression(C=10)`. Con los valores por defecto (solo palabras, `C=1`) la partición daba 0.744 y las probabilidades salían muy planas; elegí `C=10` y los n-gramas de caracteres con **validación cruzada sobre el entrenamiento** (0.736 → 0.768 → 0.811). También medí variantes sobre la partición de prueba, así que esa cifra ya no es del todo independiente.
- **Partición 75/25** (`stratify`, `random_state=42`; 375 de entrenamiento, 125 de prueba): **exactitud 0.848**.

| Intención | Precisión | Recall | F1 | Soporte |
|---|---|---|---|---|
| buscar_producto | 0.84 | 0.89 | 0.86 | 18 |
| despedida_gracias | 1.00 | 0.82 | 0.90 | 11 |
| explicar_recomendacion | 0.89 | 0.94 | 0.91 | 17 |
| info_envios | 0.85 | 0.73 | 0.79 | 15 |
| no_se | 0.76 | 0.72 | 0.74 | 18 |
| rastreo_folio | 0.89 | 0.89 | 0.89 | 18 |
| recomendar_envio | 0.72 | 0.87 | 0.79 | 15 |
| saludo | 0.92 | 0.92 | 0.92 | 13 |

- **42 frases nuevas** (`ml/datos/asistente_prueba.csv`, ninguna repetida en el dataset): **exactitud 0.905**. Errores: «¿hay noticias de mi paquete?» → buscar_producto; «necesito abono para mis plantas» → recomendar_envio; «¿cuánto sale el pothos?» → no_se; «explícame la teoría de la relatividad» → explicar_recomendacion.
- **Lectura honesta.** La diferencia entre 0.848 y 0.905 no es una mejora real: 42 frases son pocas (un acierto mueve 2.4 puntos) y las escribí yo, así que pueden compartir mi estilo con el dataset. La cifra más prudente es la de la partición, cerca de 0.85. Las confusiones más probables son entre `info_envios`, `recomendar_envio` y `explicar_recomendacion` (hablan de envíos) y con `no_se`.

## 3. Umbral de confianza: 0.40

Bajo el umbral, la pregunta se contesta como `no_se`. Medido con validación cruzada sobre el entrenamiento y sobre las 42 frases nuevas:

| Umbral | Responde (validación cruzada) | Acierto de lo que responde | Responde (42 frases) | Acierto de lo que responde | Exactitud final (42 frases) |
|---|---|---|---|---|---|
| 0.30 | 93.3 % | 84.3 % | 100 % | 90.5 % | 90.5 % |
| **0.40** | 82.9 % | 87.8 % | 92.9 % | 94.9 % | 88.1 % |
| 0.50 | 72.0 % | 92.6 % | 85.7 % | 97.2 % | 85.7 % |
| 0.60 | 62.4 % | 95.7 % | 78.6 % | 100 % | 81.0 % |

Elegí **0.40** como punto medio: subirlo reduce los errores al responder, pero rechaza cada vez más preguntas válidas (la exactitud final baja). Está en `UMBRAL_CONFIANZA` de `backend/envios/asistente/asistente.py`.

## 4. Pruebas reales del endpoint

Resultados reales de `curl` con el servidor corriendo (`python manage.py runserver`); el pedido se registró antes con el caso de corrección del Proyecto 1 (`ml/ejemplos/caso_correccion.json`, folio `VIV-20261123-0001`). Se muestra `intencion`, `confianza` y `respuesta`.

| Mensaje | Intención (confianza) | Respuesta |
|---|---|---|
| hola, buenas tardes | saludo (0.996) | ¡Hola! Soy el asistente del vivero. Puedo rastrear tu pedido con su folio, explicarte por qué te salió un envío, buscar productos del catálogo y contarte cómo son los tipos de envío. |
| ¿cómo va mi pedido viv-20261123-0001? | rastreo_folio (0.998) | Encontré el pedido VIV-20261123-0001, registrado el 2026-11-23. Va en envío térmico: caja de unicel con gel térmico, 3 día(s) estimados, costo estimado 442.00 MXN. El sistema guarda el pedido, pero no tiene seguimiento de paquetería. |
| ¿por qué me salió ese envío en el pedido VIV-20261123-0001? | explicar_recomendacion (0.98) | Tu pedido VIV-20261123-0001 salió en envío térmico. El modelo prefería humedad, pero las reglas del vivero lo descartaron porque la planta mide 150.0 cm y el empaque admite hasta 120 cm. Por eso se pasó al siguiente envío posible; el modelo le daba una confianza de 1%. Riego: Regar 24 h antes de empacar; al llegar, rociar las hojas y regar si el sustrato está seco. |
| ¿tienen helechos? | buscar_producto (0.964) | Encontré 1 producto(s) del catálogo. (`productos`: Helecho de Boston) |
| ¿qué envío me recomiendas para mandar un cactus? | recomendar_envio (0.989) | El tipo de envío lo decide el recomendador del vivero con los datos de tu planta y del destino; yo no lo elijo. Abre el formulario de nuevo envío para calcularlo. (`accion`: abrir_formulario_envio) |
| ¿qué diferencia hay entre protegido y humedad? | info_envios (0.949) | Protegido: caja reforzada con relleno y tutor para el tallo, para plantas frágiles o altas. Límites: temperatura mínima de destino: 0 °C; temperatura máxima de destino: 38 °C. Humedad: bolsa con sustrato húmedo o musgo dentro de caja ventilada, para raíz desnuda, helechos y tropicales. Límites: temperatura mínima de destino: 3 °C; plantas de hasta 120 cm. |
| ¿cuál es la capital de Francia? | no_se (0.91) | No estoy seguro de haberte entendido o no tengo esa información. Puedo rastrear tu pedido con su folio, explicarte por qué te salió un envío, buscar productos del catálogo y contarte cómo son los tipos de envío. |
| estado del pedido VIV-20200101-0001 | rastreo_folio (0.979) | No encontré un pedido con el folio VIV-20200101-0001. Revisa que esté completo. |

Errores: mensaje vacío → 400 `{"error": "falta el mensaje", "campos": ["mensaje"]}`; `GET /api/asistente/` → 405 `{"error": "método no permitido; usa POST"}`.

Pruebas automáticas: `python manage.py test` → 63 pruebas (28 del Proyecto 1 + 35 del asistente); `flutter test` → 15 (8 + 7 del chat); `flutter analyze` sin problemas.

## 5. Capturas del chat

Tomadas en Chrome con la app web contra el backend de esta carpeta (en `capturas/`; las demás imágenes de esa carpeta son del Proyecto 1). Antes registré un pedido (el ficus del caso de corrección, folio `VIV-20261123-0001`) y escribí los mensajes en el chat; las respuestas son las reales del servidor.

| Captura | Archivo | Mensaje |
|---|---|---|
| Saludo | `capturas/chat_01_saludo.jpg` | hola, buenas tardes |
| Consulta con folio | `capturas/chat_02_consulta_con_folio.jpg` | ¿cómo va mi pedido VIV-20261123-0001? (resumen del pedido) |
| Pregunta del dominio | `capturas/chat_03_pregunta_del_dominio.jpg` | ¿por qué me salió ese envío? (sin repetir el folio: usa el último que recordó el chat) |
| Fuera de dominio | `capturas/chat_04_fuera_de_dominio.jpg` | ¿cuál es la capital de Francia? |
| Extra: productos | `capturas/chat_05_productos.jpg` | ¿tienen helechos? (tarjeta que abre el detalle) |
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
| Capturas | `capturas/chat_01` a `chat_07` (sección 5) |
| Nota breve | sección 1 de este archivo |
| Análisis de patrones | [ANALISIS_PATRONES.md](ANALISIS_PATRONES.md) |
