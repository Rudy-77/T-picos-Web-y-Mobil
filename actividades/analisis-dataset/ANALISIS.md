# Análisis del dataset de envíos

## Actividad 1 — El retrato del dataset

**Contenido:** [Predicción](#predicción) · [Resultado](#resultado) · [Comparación](#comparación) · [Respuestas](#respuestas) · [Para pensar](#para-pensar)

---

### Predicción

| # | Pregunta | Predicción y razón |
|---|----------|--------------------|
| 1 | Cuando llueve, ¿qué medio domina? | **Camioneta**, porque así tanto los paquetes como el conductor se resguardan de posibles daños |
| 2 | En el centro de la ciudad, ¿qué medio domina? | **Bicicleta o moto**, porque es más práctico para evitar el tráfico; la decisión dependería del volumen del paquete |
| 3 | ¿Cuál es la distancia más larga que recorre una bicicleta? | **Aprox. 7 km**, porque una persona en bicicleta tardaría demasiado a más de esa distancia, además de que no puede llevar paquetes demasiado grandes |
| 4 | ¿Cuántos envíos tienen una etiqueta que rompe las reglas del negocio? | **0**, porque se supone que el modelo siempre sigue las reglas y si algo no encaja al 100 % lo envía al valor más cercano |

---

### Resultado

#### Dominio por clima (% por fila)

```text
medio_recomendado  bicicleta  camioneta  dron  moto
clima
despejado               32.8       16.6  13.5  37.1
lluvia                   8.5       16.7   0.0  74.8
viento_fuerte           31.7       18.4   0.0  49.9
```

#### Dominio por zona (% por fila)

```text
medio_recomendado  bicicleta  camioneta  dron  moto
zona_destino
centro                  58.4       13.5   0.0  28.0
periferia                0.9       14.0  12.6  72.5
residencial             26.2       14.6  17.3  41.9
rural                    0.0       40.8   0.0  59.2
```

#### Resumen por medio (min / mediana / max)

```text
                  distancia_km               peso_kg               volumen_l
                           min median    max     min median    max       min median     max
medio_recomendado
bicicleta                 0.37   3.42   7.00     0.1   1.76   7.99       0.3   7.78   39.70
camioneta                 0.43   8.99  59.12     0.1   6.72  80.00       0.3  31.36  400.57
dron                      2.07   9.54  14.99     0.1   1.04   2.50       0.3   4.29   11.98
moto                      0.34  10.63  39.90     0.1   2.58  24.93       0.3  11.27   89.99
```

#### Etiquetas que rompen las reglas

```text
Etiquetas imposibles 0
Empty DataFrame
Columns: [id_envio, medio_recomendado]
Index: []
```

#### Distancia por zona (km)

```text
                min  median    max
zona_destino
centro         0.34    2.79   5.91
periferia      5.23   15.75  29.39
residencial    1.06    6.98  14.80
rural         15.93   34.20  59.12
```

#### Camionetas con distancia menor a 2 km

```text
Total: 107
Con razón clara: 95
Sin razón clara: 12
      distancia_km  peso_kg  volumen_l  fragil  prioridad trafico          clima  valor_declarado_mxn
228           0.98     0.84       2.26       0  mismo_dia    bajo      despejado               295.93
1548          1.66     3.71      13.04       0    express   medio      despejado              1042.89
2736          1.74     0.95       7.32       0     normal   medio         lluvia              1061.89
3302          1.17     1.17       8.09       1    express    bajo         lluvia               380.71
3425          1.95     2.00      14.41       0     normal    alto      despejado               300.61
4962          1.53    19.72      60.55       1     normal    alto      despejado               364.46
5593          1.95    24.45      48.11       1     normal    bajo         lluvia               129.18
6797          1.34     6.51      13.14       0    express    alto  viento_fuerte               531.07
6859          1.77     0.80       3.17       1    express    bajo      despejado              1643.56
7208          1.71     0.61       3.06       1     normal    bajo      despejado               471.93
8264          1.68     2.23       6.31       1    express    alto  viento_fuerte               673.66
9491          1.20     1.33       9.96       0    express    alto         lluvia               475.32
```

---

### Comparación

#### Predicción 1 — Medio dominante cuando llueve

- **Predije:** que en lluvia la mejor opción sería la camioneta.
- **El resultado fue:** moto, con 74.8 %.
- **Fallé** porque la camioneta solo tiene 16.7 % de ser elegida.
- **Lo que no había considerado:** me fui por lo fácil, la protección del paquete, pero el modelo no toma en cuenta eso, sino qué medio es más barato para transportar. Viéndolo así, tiene sentido que sea la moto, y la camioneta solo se usaría en paquetes grandes.

#### Predicción 2 — Medio dominante en el centro

- **Predije:** que en el centro la mejor opción sería moto o bicicleta.
- **El resultado fue:** bicicleta con 58.4 % y moto con 28 %.
- **Acerté** porque son los dos medios con mayor probabilidad de ser seleccionados por el modelo si el paquete va al centro.
- **Lo que no había considerado:** si el paquete es refrigerado, tiene que ser camioneta sí o sí, por lo que no se puede descartar que sean camionetas.

#### Predicción 3 — Distancia máxima de la bicicleta

- **Predije:** que la bicicleta tendría una distancia máxima de 7 km.
- **El resultado fue:** 7 km.
- **Acerté** porque el máximo sí fue de 7 km.
- **Lo que no había considerado:** mi predicción se basó meramente en el README.

#### Predicción 4 — Etiquetas que rompen las reglas

- **Predije:** 0.
- **El resultado fue:** 0 etiquetas imposibles.
- **Acerté** porque no hubo etiquetas imposibles.
- **Lo que no había considerado:** no se marcan imposibles porque se asigna el vehículo más cercano considerando los datos. Es decir, el generador solo elige entre medios posibles y, si hay ruido, se cambia a un medio posible.

---

### Respuestas

#### 3.1 — ¿Dónde y cuándo nunca aparece el dron?

- **Zonas donde el dron vale 0.0:** Centro y Rural.
  - **Regla que lo explica:** hay una regla explícita que dice `medio == "dron" and paquete["zona_destino"] == "centro"`, por lo que el dron nunca irá al centro.
- **Climas donde el dron vale 0.0:** lluvia y viento fuerte.
  - **Regla que lo explica:** la regla explícita es `medio == "dron" and paquete["clima"] != "despejado"`. Esta regla impide que el dron viaje con un clima que no sea despejado.
- **Caso raro (zona rural):** ninguna regla de zona lo prohíbe y aun así vale 0.0. ¿Qué otra restricción del dron lo explica?
  - **Respuesta:** esto pasa porque la zona rural se encuentra a más de 15 km, que es la distancia máxima del dron.

#### 3.2 — ¿Por qué la bicicleta casi no va a la periferia?

- **Columna que lo explica:** porque abarca más del límite que puede recorrer la bicicleta, en la columna `distancia_km`.
- **Número que lo demuestra** (distancia mediana por zona frente al límite de 7 km de la bicicleta): 15.75 km, por lo que es claramente mayor que el límite máximo que puede alcanzar la bicicleta.
- **Explicación:** al abarcar bastante terreno, en periferia la distancia mínima es 5.23 km y la mediana 15.75 km, ambas por encima o cerca del límite de 7 km de la bicicleta, por lo que no puede ir a esas zonas. Además, solo 46 envíos están a menos de 7 km.

#### 3.3 — Máximos contra la tabla LIMITES

| Medio | Distancia máx. (límite) | Peso máx. (límite) | Volumen máx. (límite) |
|---|---|---|---|
| Bicicleta | 7.00 (7) | 7.99 (8) | 39.70 (40) |
| Dron | 14.99 (15) | 2.50 (2.5) | 11.98 (12) |
| Moto | 39.90 (40) | 24.93 (25) | 89.99 (90) |
| Camioneta | 59.12 (1000) | 80.00 (1000) | 400.57 (3000) |

- **Límites que se pueden adivinar mirando los datos:** los límites de la bicicleta, del dron y de la moto.
- **Límite que no se puede adivinar:** los de la camioneta.
- **Por qué:** porque los datos obtenidos no están cerca de los límites que puede alcanzar. Como en el peso: el máximo del dataset es de 80 kg y la camioneta soporta un máximo de 1 000 kg. Ningún paquete llega a ese límite, por lo cual pensaríamos que el límite es 80.

#### 3.4 — Camionetas en viajes de menos de 2 km

- **Total de camionetas con distancia menor a 2 km:** 107 camionetas.
- **Cuántas tienen una razón clara** (refrigerado, o peso/volumen que la moto no soporta): 95.
- **Cuántas no la tienen:** 12.
- **Explicación para las que no:** hay algunas que son express y algunas que son frágiles, lo que penaliza a moto, bicicleta y dron, por lo cual esas podrían ser las razones:
  - **Frágiles:** 6 de las 12 (50 %), contra 19.7 % en todo el dataset.
  - **Express:** 6 de las 12 (50 %), contra 30.4 % en todo el dataset.
  - **El resto** no tiene ninguna de esas características, y ahí aplicaría el ruido.

---

### Para pensar

> Si les dieran solo el CSV, sin las reglas, ¿podrían reconstruir las reglas del negocio a partir de los datos?

- **Reglas que sí se pueden reconstruir:** a partir de los datos sí se podrían reconstruir las reglas de los vehículos, como la bici, la moto y el dron, ya que no son muy complejas y, viendo y analizando, se podría llegar a la conclusión aproximada o correcta.
- **Reglas que no:** en mi opinión, las reglas de la camioneta, ya que con los datos no se alcanza el máximo de sus capacidades, por lo cual podríamos asumir cosas que no son en cuanto a los refrigerados, la distancia y el peso máximo.
- **Riesgo de dejar que un modelo «descubra» las reglas en lugar de escribirlas a mano:** se puede omitir información importante y asumir que así debe ser por falta de datos, mientras que si se tienen las reglas bien definidas se cubren los casos como se planean.
- **Mi postura:** yo creo que es mejor definir las reglas desde antes para poder obtener los resultados que esperamos, cubriendo los escenarios posibles como los planteamos y no adivinando.
