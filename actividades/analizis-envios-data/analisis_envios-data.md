# Análisis de envios-data

- **Nombre:** Paulo Cesar Perez Martinez
- **Matrícula:** 22121268
- **Equipo:**

**Contenido:** [Los archivos](#los-archivos) · [Predicción](#predicción) · [Resultado](#resultado) · [Comparación](#comparación) · [Patrones](#patrones-que-se-repiten) · [Para pensar](#para-pensar) · [Conclusiones](#conclusiones)

---

## Los archivos

Se probó el árbol de decisión guardado (`modelo_medios.joblib`, profundidad 8) con seis archivos de 10 000 envíos cada uno. Se calcularon los porcentajes de cada medio por archivo.

| Archivo | Moto  | Camioneta | Bicicleta | Dron  | Eskuter |
| ------- | ----- | --------- | --------- | ----- | ------- |
| envios1 | 25.0% | 25.0%     | 25.0%     | 25.0% | —       |
| envios2 | 34.7% | 14.4%     | 26.2%     | 8.6%  | 16.2%   |
| envios3 | 73.7% | 15.8%     | 7.7%      | 2.8%  | —       |
| envios4 | 57.2% | 16.9%     | 18.8%     | 7.1%  | —       |
| envios5 | 45.8% | 16.8%     | 28.0%     | 9.5%  | —       |
| envios6 | 63.1% | 32.0%     | 4.2%      | 0.7%  | —       |

- **envios1:** perfectamente balanceado, 2 500 envíos por medio.
- **envios2:** es el único con `eskuter` (16.2 %, 1 616 envíos). El modelo nunca lo vio al entrenar.
- **envios3:** domina la moto (73.7 %) y el dron es muy escaso (2.8 %).
- **envios4 y envios5:** la moto domina de forma moderada. En envios5 la bicicleta tiene más presencia (28.0 %).
- **envios6:** moto y camioneta suman cerca del 95 %. Solo hay 73 drones (0.7 %) y 424 bicicletas (4.2 %).
- **Nota sobre envios5:** es idéntico a `envios_medios.csv`, el archivo con el que se entrenó el modelo. Su resultado no es una prueba totalmente limpia (ver [Comparación](#comparación)).

---

## Predicción

| # | Pregunta | Predicción y razón |
|---|----------|--------------------|
| 1 | ¿Cómo le irá a `envios1`? | **Buena exactitud**, por estar balanceado, aunque el balance por sí solo no garantiza que sea la mejor |
| 2 | ¿Podrá predecir el `eskuter`? | **No**, porque el modelo nunca lo vio en el entrenamiento |
| 3 | ¿Qué archivo tendrá la peor exactitud? | **envios2**, ya que el 16 % de sus envíos (más de 1 600) pertenece a un medio desconocido |
| 4 | ¿Con qué se confundirá el `eskuter`? | **Moto o bicicleta**, los medios más parecidos |
| 5 | ¿Qué medio será el más difícil de acertar? | **El dron**, porque tiene pocos ejemplos en la mayoría de los archivos |
| 6 | ¿Qué pasará con el dron en `envios6`? | Solo hay 73 casos, por lo que su resultado será **poco confiable** |
| 7 | ¿Qué pasará con la exactitud en `envios3` y `envios6`? | Puede verse **alta aunque el modelo falle** en los medios minoritarios, porque la moto domina |

---

## Resultado

La columna "Siempre la mayoritaria" es la exactitud que se lograría respondiendo siempre con el medio más frecuente del archivo.

| Archivo | Exactitud | Siempre la mayoritaria | Error más notable                                        |
| ------- | --------- | ---------------------- | -------------------------------------------------------- |
| envios1 | 95.4%     | 25.0%                  | 453 drones predichos como bicicleta                      |
| envios2 | 77.7%     | 34.7%                  | 1 616 eskuter fallados (1 405 a moto, 177 a bicicleta)   |
| envios3 | 94.5%     | 73.7%                  | 204 camionetas predichas como moto                       |
| envios4 | 92.7%     | 57.2%                  | 188 camionetas y 134 bicicletas predichas como moto      |
| envios5 | 92.5%     | 45.8%                  | 171 motos predichas como bicicleta                       |
| envios6 | 96.2%     | 63.1%                  | dron con precisión de 58% (43 motos predichas como dron) |

---

## Comparación

#### Predicción 1 — Exactitud de `envios1`

- **Predije:** buena exactitud por estar balanceado, sin ser necesariamente la mejor.
- **El resultado fue:** 95.4 %. La mejor fue `envios6` con 96.2 %.
- **Acerté** en las dos partes.
- **Lo que no había considerado:** `envios6` es de los más desbalanceados y aun así sacó la mejor exactitud, porque la moto y la camioneta (95 % de los envíos) son fáciles de acertar. Un archivo balanceado tiene más peso de los medios difíciles, y el dron falla ahí: 453 drones se predijeron como bicicleta, con un recall de 81.9 %. El modelo aprendió con 9.5 % de drones y en este archivo hay 25 %.

#### Predicción 2 — El `eskuter` no se predice

- **Predije:** que no se podría predecir.
- **El resultado fue:** precisión y recall de 0.
- **Acerté** porque el árbol solo puede responder con las clases que vio al entrenar.
- **Lo que no había considerado:** nada. Un medio nuevo obliga a reentrenar.

#### Predicción 3 — Peor exactitud

- **Predije:** que `envios2` sería la peor.
- **El resultado fue:** 77.7 %, muy por debajo de los demás (92.5 % a 96.2 %).
- **Acerté** porque 1 616 envíos son de un medio imposible de predecir. Si se quitan esos envíos, los 8 384 restantes tienen una exactitud de 92.6 %, igual que los demás archivos.
- **Lo que no había considerado:** nada.

#### Predicción 4 — Con qué se confunde el `eskuter`

- **Predije:** moto o bicicleta.
- **El resultado fue:** 1 405 a moto (87 %), 177 a bicicleta (11 %) y 34 a dron.
- **Acerté** porque el eskuter está entre la bicicleta y la moto.
- **Lo que no había considerado:** que casi todo se iría a la moto y no se repartiría entre las dos.

#### Predicción 5 — El dron es el más difícil

- **Predije:** que el dron sería el más difícil.
- **El resultado fue:** el dron tiene el menor f1 de los cuatro medios conocidos en cinco de los seis archivos.
- **Acerté** en cinco de seis.
- **Lo que no había considerado:** la excepción es `envios2`. Ahí el menor f1 entre los medios conocidos es el de la moto (0.776, contra 0.834 del dron), porque 1 405 eskuter se le fueron a la moto y bajaron su precisión. Contando el eskuter, el peor es el eskuter (f1 de 0).

#### Predicción 6 — Dron poco confiable en `envios6`

- **Predije:** resultado poco confiable por tener solo 73 casos.
- **El resultado fue:** se acertaron 61 de 73 (recall de 84 %), pero la precisión es de 58 %, porque 43 motos se predijeron como dron.
- **Acerté** porque con tan pocos casos, unos cuantos errores cambian mucho la cifra.
- **Lo que no había considerado:** que el problema sería la precisión y no el recall. Como hay muchas más motos que drones, un error pequeño sobre las motos se vuelve grande frente a los pocos drones predichos.

#### Predicción 7 — Exactitud engañosa con moto dominante

- **Predije:** que la exactitud se vería alta aunque fallara en los medios minoritarios.
- **El resultado fue:** en `envios3` la exactitud es 94.5 % y la moto es 73.7 % del archivo, pero la precisión del dron es de solo 62.8 %.
- **Acerté en parte:** la exactitud oculta ese problema, pero el modelo supera siempre a la regla de responder "moto", así que no se limita a repetir el medio más común.
- **Lo que no había considerado:** que en `envios3` la camioneta también sufre (204 predichas como moto).

#### Nota sobre `envios5`

- `envios5` es el mismo archivo con el que se entrenó el modelo, así que el 92.5 % incluye envíos de entrenamiento.
- Separando los datos como en el paso 4 (`test_size=0.2`, `stratify`, `random_state=42`), el modelo obtiene **92.1 %** en los envíos que no vio y **92.6 %** en los de entrenamiento.
- La diferencia es de solo 0.4 puntos porque el árbol está limitado a profundidad 8 y no memoriza. Aun así, `envios5` sirve de referencia y no de prueba independiente.

---

## Patrones que se repiten

- **La moto recibe la mayoría de los errores.** La mayoría de las camionetas y de los eskuter mal clasificados terminan como moto. Es el medio más común y el más parecido a otros.
- **El dron se confunde con la bicicleta.** Ocurre en todos los archivos y es más fuerte en `envios1` (453 casos). Ambos se usan para paquetes ligeros y distancias cortas.
- **La moto y la bicicleta se confunden entre sí.** En `envios2` a `envios6` hay entre 42 y 171 errores de moto a bicicleta y entre 60 y 134 de bicicleta a moto.
- **Moto predicha como dron.** Son pocos casos por archivo, pero bastan para bajar la precisión del dron cuando este es escaso: 62.8 % en `envios3` y 58.1 % en `envios6`.
- **La camioneta casi nunca se predice por error.** Su precisión es de 98.9 % o más en todos los archivos. Su recall es de 85 % a 93 % en `envios2` a `envios6` (en `envios1` es 100 %), porque algunas camionetas reales se predicen como moto.

---

## Para pensar

**Si la empresa incorpora el eskuter, ¿qué haría?**

- **Postura:** reentrenar el modelo, no cubrirlo con reglas.
- **Argumentos:**
  - Sin datos del eskuter el árbol seguirá mandando esos envíos a la moto: el 87 % de los 1 616 se fue ahí.
  - Una regla escrita a mano puede descartar lo imposible (como en `reglas.py`), pero no sabe cuándo conviene un eskuter frente a una moto. Eso solo lo aprende un modelo con ejemplos.
  - Al reentrenar hay que agregar también el eskuter a `LIMITES` en las reglas del negocio.
- **Dónde está el riesgo:** el modelo no avisa cuando le llega algo que no conoce. Por eso conviene vigilar la distribución de las recomendaciones: si de pronto la moto sube y nadie cambió la flota, algo cambió.

**¿Qué medida se debe usar en lugar de la exactitud?**

- **Postura:** precisión y recall por medio, y revisar sobre todo el dron.
- **Argumentos:**
  - En `envios3` la exactitud es 94.5 % mientras el dron tiene 62.8 % de precisión, y responder siempre "moto" ya da 73.7 %.
  - El error más grave depende del negocio. Mandar un dron cuando no convenía lo mide la precisión; no usar un dron cuando sí convenía lo mide el recall.
  - Las reglas del negocio corrigen los drones imposibles (de noche, con lluvia), pero no los medios posibles y caros. Por eso la precisión no se arregla solo con reglas.

---

## Conclusiones

- En los cinco archivos que contienen solo los cuatro medios conocidos, la exactitud va de 92.5 % a 96.2 %. En todos supera ampliamente la regla de responder siempre el medio más común.
- Un medio que el modelo no vio en el entrenamiento no se puede predecir. En `envios2` el `eskuter` falló al 100 % y bajó la exactitud a 77.7 %. Si un medio nuevo se incorpora, el modelo debe volver a entrenarse.
- La exactitud sola no basta. Hay que revisar el resultado por medio, sobre todo cuando un archivo está dominado por uno solo.
- Los medios menos frecuentes (dron y bicicleta) son los menos estables. Cuando hay pocos casos, unos cuantos errores cambian mucho el resultado.
- El modelo reproduce los patrones de las etiquetas de los CSV. Que acierte no garantiza que la recomendación sea la mejor en la práctica, solo que coincide con lo que dicen los datos.
