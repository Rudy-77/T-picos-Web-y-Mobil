# Entrega · Proyecto 1 (Vivero)

Paulo Cesar Perez Martinez, 22121268. Instalación y ejecución en [README.md](README.md); patrones en [ANALISIS_PATRONES.md](ANALISIS_PATRONES.md).

## 1. Qué recomienda mi sistema frente al ejemplo de clase

El ejemplo de clase decidía **qué vehículo de reparto** usar para un paquete de mensajería a partir de su peso, volumen, distancia, clima, hora y tráfico, y sus reglas eran límites de carga y distancia de cada vehículo. Mi sistema resuelve otra pregunta: **cómo empacar y enviar plantas vivas para que lleguen sanas**. Por eso las entradas son agronómicas (tipo de planta, altura, maceta, raíz desnuda, temperatura del destino según la época, días en tránsito) y la salida es uno de cuatro empaques: `estandar`, `protegido`, `humedad` o `termico`. Las reglas tampoco son de capacidad, sino de supervivencia y costo: una planta a raíz desnuda no aguanta una caja normal, el empaque de humedad no admite plantas de más de 120 cm y pudre las suculentas, el térmico no se justifica para pedidos de menos de 150 MXN ni dura más de 5 días. Además, cada recomendación trae un **plan** con costo estimado y un **riego sugerido** (antes de empacar y al recibir), que cubre la segunda lectura de mi tema: "tipo de envío hortícola o riego sugerido". Lo que se conserva del curso es la receta técnica: `Pipeline` + `ColumnTransformer` + `DecisionTreeClassifier` guardado en `.joblib`, un adaptador que convierte probabilidades en una sugerencia, reglas que el modelo no puede saltarse y un respaldo cuando ninguna opción es válida.

## 2. Datos y métricas reales

- Dataset **sintético** (`ml/generar_dataset.py`, semilla 22121268): 9 000 filas. Clases: protegido 3 097 (34.4 %), estandar 2 536 (28.2 %), humedad 2 501 (27.8 %), termico 866 (9.6 %).
- El etiquetador se parece a las reglas pero **a propósito no es igual**: manda a `termico` aunque el valor sea menor a 150 MXN, manda a `humedad` sin mirar la altura y acepta `estandar` hasta 4 días para suculentas y plantas de exterior (la regla corta en 3). Además, 5 % de las etiquetas son ruido.
- En el dataset, **934 de 9 000 etiquetas (10.4 %)** serían prohibidas por las reglas (humedad 513, estandar 377, protegido 25, termico 19), y el modelo entrenado propone un envío prohibido en **931 filas (10.3 %)**. Esas son las situaciones en que las reglas corrigen.
- Árbol (`max_depth=8`, `min_samples_leaf=5`), 80/20 estratificado: **exactitud 91.8 %** en 1 800 filas de prueba.

| Clase | Precisión | Recall | F1 | Soporte |
|---|---|---|---|---|
| estandar | 0.902 | 0.949 | 0.925 | 507 |
| humedad | 0.960 | 0.902 | 0.930 | 500 |
| protegido | 0.919 | 0.953 | 0.936 | 620 |
| termico | 0.838 | 0.746 | 0.789 | 173 |

Matriz de confusión (filas = real, columnas = predicho):

```
           estandar  humedad  protegido  termico
estandar        481        6         13        7
humedad          17      451         19       13
protegido        16        8        591        5
termico          19        5         20      129
```

`termico` es la clase más débil: es la menos frecuente y se confunde con `estandar` y `protegido`.

## 3. Caso reproducible: las reglas corrigen al modelo

Entrada guardada en [ml/ejemplos/caso_correccion.json](ml/ejemplos/caso_correccion.json): un **ficus (interior tropical) de 150 cm** que viaja 320 km, 3 días, a 22 °C, en primavera, a la periferia, con valor de 950 MXN.

Petición:

```bash
curl -s -X POST http://127.0.0.1:8000/api/recomendar/ -H 'Content-Type: application/json' -d '{"distancia_km":320,"peso_kg":8.5,"altura_cm":150,"diametro_maceta_cm":30,"cantidad_plantas":1,"valor_declarado_mxn":950,"temperatura_destino_c":22,"dias_en_transito":3,"fragil":0,"raiz_desnuda":0,"tipo_planta":"interior_tropical","epoca":"primavera","prioridad":"normal","zona_destino":"periferia"}'
```

Respuesta real del servidor (resumida, campo `resultado`):

```json
{
  "envio": "termico",
  "confianza": 0.013,
  "preferido_por_modelo": "humedad",
  "corregido_por_reglas": true,
  "motivo": "árbol de decisión, confianza 1%; se descartó humedad porque la planta mide 150.0 cm y el empaque admite hasta 120 cm",
  "ranking": [
    {"envio": "humedad",   "probabilidad": 0.973, "posible": false},
    {"envio": "termico",   "probabilidad": 0.013, "posible": true},
    {"envio": "estandar",  "probabilidad": 0.007, "posible": true},
    {"envio": "protegido", "probabilidad": 0.007, "posible": true}
  ],
  "descartados": [{"envio": "humedad", "motivo": "la planta mide 150.0 cm y el empaque admite hasta 120 cm"}],
  "sin_opcion_valida": false
}
```

**Por qué pasa.** En los datos de entrenamiento, las plantas tropicales con 3 días o más de tránsito se etiquetaron como `humedad`, sin importar su altura (el etiquetador no la mira). El árbol aprendió ese patrón y está 97.3 % seguro. Pero la regla de negocio de `humedad` (`envios/reglas.py`, `LIMITES["humedad"]["altura_max_cm"] = 120`) dice que ese empaque no admite plantas de más de 120 cm. El recomendador (`envios/recomendador.py`) recorre el ranking de mayor a menor probabilidad, descarta `humedad` y elige la primera opción posible, `termico`, marcando `corregido_por_reglas: true` y explicando el motivo.

**Lectura honesta.** La alternativa elegida tiene solo 1.3 % de confianza: el árbol tiene hojas casi puras y las demás clases solo reciben lo que deja el ruido. Por eso `termico` gana a `protegido` por muy poco, aunque agronómicamente un ficus alto también cabría en caja protegida. El sistema no lo oculta: muestra la confianza baja y la corrección, que es justo la información que el usuario necesita para decidir.

**Cómo reproducirlo:**
- Con `curl`, con el comando de arriba.
- En la app: catálogo → buscar "ficus" → *Ficus lyrata (1.5 m)* → "Calcular envío" → distancia 320, días en tránsito 3 → "Recomendar envío". (El producto del catálogo es frágil y la época se precarga según el mes; con esos cambios la respuesta probada también fue `termico` corregido, 1.3 %.)
- Con la prueba automática `test_caso_reproducible_de_correccion` (`backend/envios/tests/test_recomendador.py`) y `test_recomendar_reproduce_el_caso_de_correccion` (`backend/envios/tests/test_api.py`).

**Caso extremo: ninguna opción es válida.** Raíz desnuda, −3 °C, 6 días y 100 MXN: `estandar` (raíz desnuda y frío), `protegido` (frío), `humedad` (frío) y `termico` (más de 5 días y valor bajo) quedan descartados. La respuesta usa `termico` como respaldo con `sin_opcion_valida: true`, confianza 0 y el motivo "ningún envío cumple las reglas; se usa termico como respaldo y conviene revisar el pedido con el encargado del vivero" (prueba `test_sin_opcion_valida_usa_respaldo_termico`).

## 4. Guion de capturas

Con el backend en `127.0.0.1:8000` y la app en Chrome (`flutter run -d chrome`):

1. **Catálogo:** la lista con los 20 productos (plantas, macetas, sustratos, fertilizantes).
2. **Búsqueda:** escribir "ficus" y mostrar el resultado.
3. **Detalle:** *Ficus lyrata (1.5 m)* con precio, existencias y datos físicos.
4. **Entradas:** el formulario precargado (150 cm, maceta 32 cm, frágil) después de cambiar distancia a 320 y días a 3.
5. **Recomendación:** tarjeta "Térmico", confianza 1.3 % y el motivo.
6. **Reglas:** el aviso "Las reglas corrigieron al modelo", el ranking con Humedad 97.3 % bloqueada y la sección "Descartados por las reglas".
7. **Plan:** empaque, costo estimado, indicación y riego sugerido.
8. **Registro y folio:** "Registrar pedido" → pantalla de confirmación con el folio `VIV-AAAAMMDD-0001`.
9. **Consulta por folio:** ícono de recibo en el catálogo → escribir el folio → el pedido guardado con la misma recomendación.
10. **Error de red (opcional):** detener Django y pulsar buscar o reintentar: mensaje "No se pudo conectar..." con botón Reintentar.
11. **Respaldo del servidor (opcional):** la respuesta de `curl` del punto 3 y la salida de `python manage.py test`.
