# Análisis de patrones · Proyecto 2 (Vivero)

Paulo Cesar Perez Martinez, 22121268. Todo lo que se menciona aquí está en el código entregado; las rutas son relativas a `proyectos/proyecto2/`. Los patrones 1 a 10 vienen del Proyecto 1 y siguen vigentes; los 11 a 15 son nuevos del asistente.

## Backend (Django, API JSON)

**1. Strategy: tipos de envío.** `backend/envios/tipos_envio.py`: la clase abstracta `TipoEnvio` define `planear(paquete)` y hay una clase por envío (`EnvioEstandar`, `EnvioProtegido`, `EnvioHumedad`, `EnvioTermico`), cada una con su empaque, su tarifa y su indicación. `crear_tipo_envio(nombre)` elige la estrategia a partir del diccionario `TIPOS_ENVIO` (una fábrica simple). Quien arma la respuesta (`servicios.recomendar`) solo hace `crear_tipo_envio(sugerencia.envio).planear(paquete)`.
*Qué evita:* una cadena de `if envio == "estandar" ... elif ...` repetida en las vistas, y tener que tocar código que ya funciona para agregar o cambiar un envío: un envío nuevo es una clase nueva más una entrada en `TIPOS_ENVIO`.
*Lo que no es Strategy:* las reglas de `backend/envios/reglas.py` no son una estrategia por envío; son una tabla de datos (`LIMITES`) que lee una sola función (`motivo_descarte` / `es_posible`). Se dejó así porque casi todas las reglas son límites numéricos y una tabla se lee y se defiende más fácil que cuatro clases casi vacías.

**2. Adapter: el modelo de scikit-learn.** `backend/envios/recomendador.py`: `RecomendadorArbol` envuelve el `Pipeline` cargado del `.joblib`, que solo sabe responder `predict_proba` sobre un `DataFrame`, y lo convierte en la interfaz que el resto del sistema entiende: `RecomendadorIA.sugerir(paquete) -> Sugerencia` (envío, confianza, preferido por el modelo, corregido por reglas, ranking, descartados, motivo). Ahí mismo se aplican las reglas sobre el ranking y el respaldo `termico` cuando nada es posible.
*Qué evita:* que las vistas o los servicios dependan de pandas, del orden de `classes_` o del formato de scikit-learn. Si se cambia el árbol por otro modelo, basta otra clase que implemente `RecomendadorIA`.
*Relacionado:* `obtener_recomendador()` usa `@lru_cache(maxsize=1)` para crear **una sola instancia por proceso** (efecto de Singleton sin una clase especial) y así no leer el `.joblib` del disco en cada petición.

**3. Repository: acceso a datos.** `backend/envios/repositorios.py`: `ProductoRepositorio.listar(texto, categoria)` / `obtener(id)` y `PedidoRepositorio.por_folio(folio)` / `siguiente_folio()` / `crear(...)`. Son el único lugar que escribe consultas del ORM (`Q`, `icontains`, `select_related`) y el único que sabe cómo se arma y se reintenta el folio `VIV-AAAAMMDD-0001`.
*Qué evita:* consultas repetidas y dispersas por vistas y servicios, y que un cambio en la búsqueda o en el formato del folio obligue a editar varios archivos. Los modelos de `backend/envios/models.py` (`Producto`, `Pedido`) quedan como definición de tablas.

**4. Facade: servicios.** `backend/envios/servicios.py`: `recomendar(datos)` y `registrar_pedido(datos)` coordinan, en ese orden, la validación de las 14 entradas (`leer_caracteristicas`), el recomendador (Adapter), la estrategia de envío (Strategy) y el repositorio. `registrar_pedido` siempre recalcula en el servidor e ignora cualquier `resultado` que mande el cliente.
*Qué evita:* vistas gordas con lógica de negocio mezclada con HTTP, y que la API de recomendar y la de registrar calculen de forma distinta. Las vistas de `backend/envios/views.py` solo leen JSON, llaman a la fachada y responden.

**5. Front Controller: entrada y rutas.** Django recibe todas las peticiones en un solo punto (`backend/vivero_api/wsgi.py` → manejador de Django), las pasa por la cadena de `MIDDLEWARE` (`backend/vivero_api/settings.py`) y las reparte con `backend/vivero_api/urls.py` (`/api/` → `backend/envios/urls.py`) a la vista que corresponde. El middleware propio `CorsSimpleMiddleware` (`backend/vivero_api/cors.py`) aprovecha ese punto único para agregar CORS a todas las respuestas de `/api/`, incluidas las de error y las `OPTIONS`.
Al final de `backend/envios/urls.py`, una ruta comodín manda cualquier otra dirección de `/api/` a `ruta_no_encontrada`, y el decorador `solo_metodo` de `views.py` responde 405; así todos los errores de la API salen en JSON.
*Qué evita:* repetir en cada vista el manejo de encabezados, CSRF o CORS, y tener rutas sueltas sin un mapa central.

**6. MVC (en Django, MTV) a grandes rasgos.** Modelo: `backend/envios/models.py`. Vista/controlador: `backend/envios/views.py` + `urls.py`. No hay plantillas HTML: la "vista" para el usuario es la app Flutter, y el backend solo entrega JSON (`producto_a_dict`, `pedido_a_dict` en `servicios.py`). La separación es: datos en SQLite, decisiones en el servidor, presentación en el cliente.
*Qué evita:* que el modelo y las reglas viajen al cliente o que la app tenga que conocer la base de datos.

## Cliente (Flutter)

**7. Capa de servicio + inyección por constructor.** `app_flutter/lib/servicios/api_vivero.dart`: `ApiVivero` es el único lugar que conoce las URLs, `http`, JSON y los códigos de error, y los convierte en objetos (`Producto`, `Recomendacion`, `Pedido` en `lib/modelos/`) o en un `ErrorApi` con mensaje legible. Se crea una vez en `lib/main.dart` y se pasa por constructor a cada pantalla; su `http.Client` también se puede inyectar.
*Qué evita:* `http.get` y `jsonDecode` repartidos en las pantallas, y pruebas que necesiten el servidor: `test/widget_test.dart` y `test/chat_test.dart` usan `MockClient` para probar el catálogo, el error de red con reintento, el aviso de corrección y el chat sin Django. La URL base sale de `lib/config.dart` (`--dart-define=API_BASE_URL`), sin tocar código para apuntar a otro servidor.

**8. Composición de UI.** La interfaz se arma con widgets pequeños reutilizables: `lib/widgets/panel_recomendacion.dart` (`PanelRecomendacion`) se usa igual en la pantalla de resultado y en la consulta por folio, y `lib/widgets/estados.dart` (`Cargando`, `VistaError`, `VistaVacia`) en todas las pantallas que esperan al servidor.
*Qué evita:* duplicar el dibujo de la recomendación (confianza, corrección, ranking, descartados, plan) y que cada pantalla muestre los errores de red de forma distinta.

**9. Manejo de estado: `StatefulWidget` + `FutureBuilder`.** Cada pantalla que habla con el servidor (`lib/pantallas/catalogo.dart`, `detalle_producto.dart`, `resultado.dart`, `confirmacion.dart`, `consulta_folio.dart`) guarda en su estado **solo el `Future`** de la petición actual; al buscar o reintentar, se crea otro con `setState` y el `FutureBuilder` decide qué mostrar (cargando, error con reintento o datos).
*Por qué así y no `ChangeNotifier`/Provider:* ningún dato se comparte entre pantallas; cada una pide lo suyo y lo pasa a la siguiente por constructor. Un estado global agregaría código sin resolver un problema real. En el Proyecto 2 apareció un único dato compartido, el último folio confirmado, y se resolvió sin un estado global: es un `ValueNotifier<String?>` (`ultimoFolio`) dentro de `ApiVivero` (`lib/servicios/api_vivero.dart`), que ya llega a todas las pantallas por constructor. `registrarPedido` lo actualiza al confirmar un pedido y `lib/pantallas/chat.dart` lo lee y lo manda como contexto. `PantallaChat` sigue siendo un `StatefulWidget` simple (lista de mensajes y `_esperando`); no hizo falta Provider.
*Detalle aprendido en las pruebas:* el `setState` debe ir con llaves (`setState(() { _futuro = ...; })`); con `=>` devuelve el `Future` y Flutter lanza un error. La prueba de reintento lo detectó.

**10. Navegación como pila.** `Navigator.push` con `MaterialPageRoute` lleva del catálogo al detalle, al formulario, al resultado y a la confirmación; la confirmación usa `popUntil((ruta) => ruta.isFirst)` para volver al catálogo y no permite regresar con la flecha (`automaticallyImplyLeading: false`).
*Qué evita:* que la flecha de la confirmación regrese al resultado e invite a registrar el mismo pedido otra vez, y tener que mantener rutas con nombre para un flujo que es lineal. Límite honesto: el botón "atrás" del navegador sí puede regresar; evitar duplicados del todo requeriría una llave de idempotencia en el servidor (anotado en el README).

## Asistente del comprador (Proyecto 2)

**11. Adapter: el clasificador de intenciones.** `backend/envios/asistente/clasificador.py`: `ClasificadorTfidf` envuelve el `Pipeline` de scikit-learn cargado de `modelo_asistente.joblib` (que solo sabe devolver `predict_proba` y `classes_`) y lo convierte en la interfaz que entiende el resto del servidor: `ClasificadorIntenciones.clasificar(texto) -> Intencion(nombre, confianza)`. Antes de predecir aplica `normalizar` (`asistente/texto.py`), que cambia el folio por un token.
*Qué evita:* que `asistente.py` dependa de `joblib`, de scikit-learn o del orden de `classes_`; ese archivo solo conoce `Intencion`. En `tests/test_asistente.py`, `ClasificadorFalso` reemplaza al modelo real para probar cada intención sin entrenar nada. Es el mismo patrón que `RecomendadorArbol` (`recomendador.py`), aplicado a un segundo modelo con otra entrada (texto) y otra salida (intención).
*Carga única:* `obtener_clasificador()` usa `@lru_cache(maxsize=1)`: el `.joblib` se lee en la primera pregunta y una sola vez por proceso, igual que `obtener_recomendador()`. El umbral de confianza **no** está en el Adapter sino en `asistente.py` (`UMBRAL_CONFIANZA = 0.40`), para que las pruebas lo ejerciten con un clasificador falso.

**12. Inyección de las consultas en `responder` (una técnica, no un patrón con nombre).** `backend/envios/asistente/asistente.py`: `responder(mensaje, contexto, buscar_pedido, listar_productos, clasificador=None)` recibe las consultas como funciones. La vista (`backend/envios/views.py`, `asistente_chat`) le pasa `servicios.buscar_pedido` y `listar_para_asistente`, que usa `ProductoRepositorio`. Es inyección de dependencias por parámetro; no es Strategy porque no hay una familia de clases intercambiables con un nombre de dominio.
*Qué evita:* que el módulo del asistente importe la base de datos o los modelos de Django. En `PruebasResponder` las consultas son `lambda` y las pruebas corren sin base de datos.
*Límite honesto:* `asistente.py` sí importa directamente `reglas.py` y `tipos_envio.py` (datos y clases puras, sin Django) para describir los envíos, así que esa parte no está inyectada.

**13. Separación cliente/servidor: el `.joblib` no vive en Flutter.** Los dos modelos (`modelo_vivero.joblib` y `modelo_asistente.joblib`) están solo en `backend/envios/modelo/`. En `app_flutter/` no hay ningún `.joblib` ni dependencia de aprendizaje automático: `pubspec.yaml` declara solo `http` y `google_fonts`. El cliente manda texto y, opcionalmente, el último folio; recibe JSON. El entrenamiento está fuera de Django y de la petición: `ml/entrenar_asistente.py` (en `backend/` no hay ningún `fit`). La única pieza compartida entre entrenamiento y servidor es `asistente/texto.py` (`normalizar`), importada por ambos para que el texto se prepare igual.
*Qué evita:* que cambiar el modelo obligue a publicar de nuevo la app, y que el modelo (o sus versiones de scikit-learn) viaje al dispositivo del comprador.

**14. Qué cambia en el cliente y qué en el backend.**

| | Cliente (Flutter) | Backend (Django) |
|---|---|---|
| Pantalla / ruta | `lib/pantallas/chat.dart` (`PantallaChat`) y un ícono en `catalogo.dart` | `POST /api/asistente/`: `views.asistente_chat`, `urls.py` |
| Estado | lista de mensajes y bandera `_esperando` en el `State`; el último folio vive en `ApiVivero.ultimoFolio` | sin estado: el folio llega en `contexto` |
| Red | indicador mientras responde, error con «Reintentar» que no duplica la pregunta (`ErrorApi`) | errores JSON: 400 con `error`, 405 con `error` |
| Datos | `lib/modelos/respuesta_asistente.dart`, `mensaje_chat.dart`; `ApiVivero.preguntar` | `asistente/asistente.py`, carga perezosa del modelo, consultas a `servicios` y `repositorios` |

Las demás pantallas (catálogo, detalle, formulario, resultado, confirmación, consulta por folio) y los endpoints del Proyecto 1 no cambian: el chat reutiliza `PantallaDetalleProducto` y `PantallaFormularioEnvio`, así que se percibe un solo producto. El chat reutiliza también el manejo de errores de `ApiVivero._pedir` y la prueba usa el mismo `MockClient` del Proyecto 1 (`test/chat_test.dart`).

**15. Diferencia de responsabilidad: recomendador del dominio frente a asistente.**

| | Recomendador (Proyecto 1) | Asistente (Proyecto 2) |
|---|---|---|
| Pregunta que contesta | ¿qué envío le conviene a este pedido? | ¿qué quiere el comprador y qué dato del sistema lo contesta? |
| Entrada | 14 características de planta y destino (`servicios.leer_caracteristicas`) | un mensaje de texto (máximo 500 caracteres) |
| Modelo | árbol de decisión (`modelo_vivero.joblib`) + reglas (`reglas.py`) | TF-IDF + regresión logística (`modelo_asistente.joblib`) |
| Salida | `Sugerencia` y plan (`recomendador.py`, `tipos_envio.py`) | `Intencion` y una respuesta armada con datos guardados |
| ¿Decide el envío? | sí, es el único que lo hace | **no**: remite al formulario o lee lo ya guardado |

El asistente nunca llama a `servicios.recomendar` ni a `obtener_recomendador` (`asistente/` no importa el recomendador ni `servicios`). Para «¿por qué me salió X?» lee el `resultado` guardado por el Proyecto 1 en el `Pedido`; para «¿qué envío uso?» devuelve una `accion` que abre el formulario. La prueba `test_recomendar_envio_no_elige_un_envio` (`tests/test_asistente.py`) lo garantiza.

**Límites y seguridad (no son patrones, pero conviene decirlos).** Los folios son consecutivos y por tanto adivinables, y `GET /api/pedidos/<folio>/` ya devuelve el pedido completo desde el Proyecto 1; el asistente expone solo un resumen, pero eso no es control de acceso. El `ultimo_folio` lo manda el cliente: sirve de comodidad, no de autorización. La búsqueda de productos hereda el `icontains` de SQLite, que distingue acentos. El sistema guarda pedidos pero no tiene estado de paquetería, y por eso el asistente lo avisa en vez de inventarlo.
