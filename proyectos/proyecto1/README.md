# Proyecto 1 · Vivero: recomendador de envío hortícola

Tópicos Selectos de Aplicaciones Web y Móviles, TECNM, 9.º semestre.
Paulo Cesar Perez Martinez, matrícula 22121268. Dominio: **vivero / plantas**.

El sistema recomienda **cómo enviar un pedido de plantas** y sugiere **cómo regarlas** antes y después del viaje:

| Envío | Para qué sirve |
|---|---|
| `estandar` | caja normal, sin cuidados especiales |
| `protegido` | caja reforzada con relleno, para plantas frágiles o altas |
| `humedad` | empaque que retiene humedad (raíz desnuda, helechos, tropicales) |
| `termico` | caja aislada con gel, para destinos muy fríos o muy calientes |

Un **árbol de decisión** (`.joblib`) propone el envío y unas **reglas del negocio** lo corrigen si propone algo que el vivero no puede ofrecer. Todo corre en un monolito **Django + SQLite**; la app **Flutter** solo consume JSON.

Más documentación:
- [ENTREGA.md](ENTREGA.md): caso en que las reglas corrigen al modelo, comparación con el ejemplo de clase, métricas y guion de capturas.
- [ANALISIS_PATRONES.md](ANALISIS_PATRONES.md): patrones de diseño en el backend y en la app.

## Estructura

```
proyecto1/
  requirements.txt          dependencias de Python (versiones del curso)
  ml/
    generar_dataset.py      dataset SINTÉTICO y reproducible (semilla 22121268)
    entrenar_modelo.py      entrena el árbol y guarda el .joblib en el backend
    datos/envios_vivero.csv 9 000 filas generadas
    ejemplos/caso_correccion.json  caso reproducible de corrección por reglas
  backend/                  proyecto Django (paquete vivero_api, app envios)
    manage.py, db.sqlite3
    vivero_api/             settings, urls (entrada de rutas), cors.py (CORS mínimo)
    envios/
      reglas.py             LIMITES y es_posible: lo que el modelo no puede saltarse
      tipos_envio.py        una estrategia por envío con planear() (empaque, costo, riego)
      recomendador.py       adapta el modelo de scikit-learn a una Sugerencia
      servicios.py          valida, recomienda y registra pedidos (facade)
      repositorios.py       consultas y folio (VIV-AAAAMMDD-0001)
      models.py, views.py, urls.py, admin.py
      modelo/modelo_vivero.joblib
      management/commands/cargar_datos_prueba.py
      tests/                pruebas de reglas, recomendador y endpoints
  app_flutter/              app Flutter (paquete vivero_app)
```

## Requisitos

- Python 3.14 (probado con 3.14.8).
- Flutter 3.47 / Dart 3.13 y Google Chrome. Para Android hace falta el Android SDK y un emulador (no se probó en este equipo; ver más abajo).

## 1. Entorno de Python

Desde `proyectos/proyecto1/`:

```bash
python3 -m venv .venv
```

```bash
source .venv/bin/activate
```

```bash
pip install -r requirements.txt
```

En Windows, el segundo paso es `.venv\Scripts\activate`.

> El modelo se entrena y se sirve con **scikit-learn 1.9.1**. Si se cambia la versión, hay que regenerar el `.joblib` (paso 2).

## 2. Dataset y modelo (opcional: ya vienen en el repositorio)

El dataset es **sintético**: no existe uno público para esta decisión. `generar_dataset.py` crea pedidos coherentes (la temperatura depende de la época; los días en tránsito, de la distancia, la zona y la prioridad) y los etiqueta con un criterio agronómico que **no es idéntico a las reglas** y tiene ~5 % de ruido, para que el árbol no copie las reglas y estas puedan corregirlo.

```bash
python ml/generar_dataset.py
```

```bash
python ml/entrenar_modelo.py
```

El primero escribe `ml/datos/envios_vivero.csv` y el segundo imprime la exactitud, el reporte por clase y la matriz de confusión, y guarda `backend/envios/modelo/modelo_vivero.joblib`. Las rutas son relativas a cada script, así que se pueden ejecutar desde cualquier carpeta. Con la misma semilla se obtiene el mismo CSV y el mismo modelo.

## 3. Backend Django

Desde `proyectos/proyecto1/backend/` (con el entorno activado):

```bash
python manage.py migrate
```

```bash
python manage.py cargar_datos_prueba
```

```bash
python manage.py runserver 127.0.0.1:8000
```

`db.sqlite3` ya viene con las tablas y los 20 productos de prueba; `cargar_datos_prueba` se puede ejecutar varias veces sin duplicar. Para empezar de cero, borra `db.sqlite3` y repite los dos primeros comandos.

Pruebas automáticas (28: reglas, estrategias, recomendador, caso de corrección y endpoints):

```bash
python manage.py test
```

### Endpoints

| Método y ruta | Qué hace |
|---|---|
| `GET /api/productos/?q=&categoria=` | listado del catálogo con búsqueda (`q`) y filtro por categoría |
| `GET /api/productos/<id>/` | detalle de un producto |
| `POST /api/recomendar/` | recibe las 14 características y devuelve la recomendación, sin registrar nada |
| `POST /api/pedidos/` | recalcula la recomendación en el servidor, registra el pedido y devuelve el folio (HTTP 201) |
| `GET /api/pedidos/<folio>/` | consulta un pedido por folio |

Cuerpo de `POST /api/recomendar/` (y de `/api/pedidos/`, que además acepta `producto_id` y `cantidad` opcionales):

```json
{
  "distancia_km": 320, "peso_kg": 8.5, "altura_cm": 150, "diametro_maceta_cm": 30,
  "cantidad_plantas": 1, "valor_declarado_mxn": 950, "temperatura_destino_c": 22,
  "dias_en_transito": 3, "fragil": 0, "raiz_desnuda": 0,
  "tipo_planta": "interior_tropical", "epoca": "primavera",
  "prioridad": "normal", "zona_destino": "periferia"
}
```

Valores aceptados: `tipo_planta` ∈ {suculenta, interior_tropical, exterior, frutal, hortaliza, helecho}; `epoca` ∈ {primavera, verano, otono, invierno}; `prioridad` ∈ {normal, express}; `zona_destino` ∈ {urbana, periferia, rural}. `fragil` y `raiz_desnuda` aceptan 0/1 o `true`/`false`. También se validan rangos razonables (por ejemplo, `peso_kg` entre 0.01 y 1 000, `distancia_km` entre 0.1 y 5 000, `dias_en_transito` entero de 1 a 30, temperatura de −30 a 55 °C; `diametro_maceta_cm` puede ser 0 si la planta va sin maceta). Si falta un campo o un valor no es válido, la respuesta es 400 con `error` y `campos`. Las rutas inexistentes (404) y los métodos no permitidos (405) también responden en JSON.

La respuesta trae `envio`, `confianza`, `preferido_por_modelo`, `corregido_por_reglas`, `sin_opcion_valida`, `motivo`, `ranking` (con `posible` por envío), `descartados` (con el motivo de cada regla) y `plan` (`empaque`, `dias`, `costo_estimado_mxn`, `indicacion`, `riego_sugerido`).

Prueba rápida con `curl` (el caso de corrección):

```bash
curl -s -X POST http://127.0.0.1:8000/api/recomendar/ -H 'Content-Type: application/json' -d '{"distancia_km":320,"peso_kg":8.5,"altura_cm":150,"diametro_maceta_cm":30,"cantidad_plantas":1,"valor_declarado_mxn":950,"temperatura_destino_c":22,"dias_en_transito":3,"fragil":0,"raiz_desnuda":0,"tipo_planta":"interior_tropical","epoca":"primavera","prioridad":"normal","zona_destino":"periferia"}'
```

**CORS:** Flutter web corre en otro origen. `vivero_api/cors.py` agrega los encabezados CORS solo en `/api/` y solo para `http://localhost:*` y `http://127.0.0.1:*`. Para permitir otro origen, define `CORS_ORIGENES_EXTRA` (separados por comas) antes de arrancar el servidor.

**Stock:** registrar un pedido **no descuenta stock**; en este proyecto el pedido solo deja constancia de la operación y de la recomendación.

## 4. App Flutter

Desde `proyectos/proyecto1/app_flutter/`, con el backend corriendo:

```bash
flutter pub get
```

```bash
flutter run -d chrome
```

La URL base se configura sin tocar código, con `--dart-define` (por defecto `http://127.0.0.1:8000`):

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

En el **emulador de Android**, `127.0.0.1` es el propio emulador; la PC se ve como `10.0.2.2`:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

En un celular físico, usa la IP de la PC en la red WiFi y arranca Django con `runserver 0.0.0.0:8000` y `DJANGO_ALLOWED_HOSTS=<esa IP>`. El manifiesto de Android ya pide el permiso `INTERNET` y permite `http` sin TLS (solo para desarrollo). **Android no se probó** en este equipo porque no tiene el Android SDK; solo se probó en Chrome.

Análisis y pruebas de la app:

```bash
flutter analyze
```

```bash
flutter test
```

Pantallas: catálogo con búsqueda y botones para filtrar por categoría (plantas, macetas, sustratos, fertilizantes) → detalle → formulario (precargado con los datos de la planta) → recomendación (confianza, aviso de corrección, ranking, descartados y plan con riego) → confirmación con folio. Desde el catálogo también se abre la consulta por folio y un formulario vacío ("Nuevo envío").

## Limitaciones conocidas

- El dataset es sintético: el modelo aprende el criterio con el que se generó, no datos reales de un vivero.
- El árbol tiene hojas casi puras; cuando las reglas descartan la clase preferida, la alternativa suele tener confianza baja (1 a 3 %). Se muestra tal cual, sin maquillarla.
- El folio se ordena como texto: funciona hasta 9 999 pedidos por día.
- Si se pierde la respuesta de un `POST /api/pedidos/` y el usuario pulsa "Reintentar", podría registrarse un pedido duplicado (no hay llave de idempotencia).
- Las fuentes (Barlow Condensed y Barlow, paquete `google_fonts` 8) se descargan de Google Fonts la primera vez que se abre la app; sin internet, la app usa la fuente del sistema y funciona igual. Las pruebas usan el tema con la fuente del sistema (`temaVivero(fuentesWeb: false)`) para no depender de la red.
- La compilación *release* de Android se firma con las llaves de depuración (configuración por defecto de Flutter); sirve para pruebas, no para publicar.
