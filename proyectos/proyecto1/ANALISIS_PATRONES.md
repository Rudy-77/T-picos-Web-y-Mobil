# Análisis de patrones · Proyecto 1 (Vivero)

Paulo Cesar Perez Martinez, 22121268. Todo lo que se menciona aquí está en el código entregado; las rutas son relativas a `proyectos/proyecto1/`.

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
*Qué evita:* `http.get` y `jsonDecode` repartidos en las pantallas, y pruebas que necesiten el servidor: `test/widget_test.dart` usa `MockClient` para probar el catálogo, el error de red con reintento y el aviso de corrección sin Django. La URL base sale de `lib/config.dart` (`--dart-define=API_BASE_URL`), sin tocar código para cambiar entre Chrome y el emulador.

**8. Composición de UI.** La interfaz se arma con widgets pequeños reutilizables: `lib/widgets/panel_recomendacion.dart` (`PanelRecomendacion`) se usa igual en la pantalla de resultado y en la consulta por folio, y `lib/widgets/estados.dart` (`Cargando`, `VistaError`, `VistaVacia`) en todas las pantallas que esperan al servidor.
*Qué evita:* duplicar el dibujo de la recomendación (confianza, corrección, ranking, descartados, plan) y que cada pantalla muestre los errores de red de forma distinta.

**9. Manejo de estado: `StatefulWidget` + `FutureBuilder`.** Cada pantalla que habla con el servidor (`lib/pantallas/catalogo.dart`, `detalle_producto.dart`, `resultado.dart`, `confirmacion.dart`, `consulta_folio.dart`) guarda en su estado **solo el `Future`** de la petición actual; al buscar o reintentar, se crea otro con `setState` y el `FutureBuilder` decide qué mostrar (cargando, error con reintento o datos).
*Por qué así y no `ChangeNotifier`/Provider:* ningún dato se comparte entre pantallas; cada una pide lo suyo y lo pasa a la siguiente por constructor. Un estado global agregaría código sin resolver un problema real. Si en el Proyecto 2 el asistente necesita el carrito o el último folio en varias pantallas, ahí sí convendría un `ChangeNotifier`.
*Detalle aprendido en las pruebas:* el `setState` debe ir con llaves (`setState(() { _futuro = ...; })`); con `=>` devuelve el `Future` y Flutter lanza un error. La prueba de reintento lo detectó.

**10. Navegación como pila.** `Navigator.push` con `MaterialPageRoute` lleva del catálogo al detalle, al formulario, al resultado y a la confirmación; la confirmación usa `popUntil((ruta) => ruta.isFirst)` para volver al catálogo y no permite regresar con la flecha (`automaticallyImplyLeading: false`).
*Qué evita:* que la flecha de la confirmación regrese al resultado e invite a registrar el mismo pedido otra vez, y tener que mantener rutas con nombre para un flujo que es lineal. Límite honesto: el botón "atrás" del navegador o de Android sí puede regresar; evitar duplicados del todo requeriría una llave de idempotencia en el servidor (anotado en el README).
