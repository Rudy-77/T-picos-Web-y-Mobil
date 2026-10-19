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
f
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

---

## Actividad 2 — La hora y el dron

### Predicción

- **¿Cuántos drones salen a las 3:00?**
  - **Mi predicción:** creo que no saldrán drones.
  - **Por qué lo creo:** porque el dron no trabaja en esas horas ni durante la noche.
- **¿Qué porcentaje de los envíos sale de noche (antes de las 6:00 o desde las 21:00)?**
  - **Mi predicción:** creo que menos del 20 %.
  - **Por qué lo creo:** porque el dron no vuela de noche, por lo que no saldrán pedidos de dron, y no es común que salgan bicicletas de noche.

### Resultado

#### Envíos por hora y medio

```text
medio_recomendado  bicicleta  camioneta  dron  moto
hora_salida                                        
0                          2         12     0    63
1                          6         11     0    49
2                          5         19     0    59
3                          4         13     0    60
4                          2         10     0    47
5                          8         25     0   116
6                         94         50    33   136
7                        204         92    68   233
8                        205        118    57   252
9                        187         97    65   279
10                       192        123    68   273
11                       178        107    72   283
12                       217        111    82   297
13                       211        112    70   284
14                       204        103    72   274
15                       199        122    81   303
16                       213        108    59   260
17                       192         97    69   292
18                       162         97    72   248
19                       166         78    45   199
20                       115         72    35   160
21                        20         58     0   240
22                         5         28     0   116
23                         5         15     0    55
```

#### Porcentaje de envíos de noche

```text
Envíos de noche: 1053
Envíos de día: 8947
Porcentaje de noche: 10.53 %
```

#### Gráfica

![Envíos por hora y medio](horas.png)

### Comparación

| | Mi predicción | Resultado real | ¿Acerté? |
|---|---|---|---|
| Drones a las 3:00 | 0 | 0 | Sí |
| % de envíos de noche | < 20 % | 10.53 % | Sí |

- **Qué me sorprendió o por qué fallé:** que las motos son el vehículo que más trabaja de noche y que las bicicletas casi desaparecen en esas horas.

### Respuestas

#### 2.1 — ¿En qué horas no hay ni un solo dron? ¿Coincide exactamente con la regla?

- **Horas sin ningún dron:** 0, 1, 2, 3, 4, 5, 21, 22 y 23 h.
- **¿Coincide con la regla (solo de 6:00 a 20:59)?** Sí, coincide con la regla del horario del dron.
- **Explicación:** la regla solo permite que el dron trabaje en cierto horario, por lo que en las demás horas no hay ningún dron trabajando.

#### 2.2 — ¿Cuántos envíos de noche hay comparados con los de día? ¿Qué consecuencia tiene para lo que el modelo puede aprender sobre la noche?

- **Envíos de noche:** 1 053 envíos.
- **Envíos de día:** 8 947 envíos.
- **Consecuencia para el modelo:** el modelo tiene muy pocos ejemplos de la noche, por lo que le puede costar saber qué hacer en esas situaciones.

#### 2.3 — Entre las 20:00 y las 21:00 las bicicletas casi desaparecen y las motos aumentan. ¿Qué lo explica según el README.md?

- **Qué dice el README.md:** que la noche penaliza a las bicicletas, por lo que es normal que las motos se lleven los paquetes que deberían ser para bicicleta.
- **Explicación con mis palabras:** las motos son una mejor opción de noche, por eso las bicicletas se ven muy reducidas.

#### 2.4 — ¿Por qué a un árbol le cuesta representar «de noche»? ¿Cuántas preguntas sobre la hora necesitaría como mínimo?

- **Por qué le cuesta:** porque la noche son dos tramos separados.
- **Número mínimo de preguntas y cuáles serían:** creo que un mínimo de 2 preguntas:
  1. ¿Hora ≥ 21?
  2. ¿Hora ≤ 5?

### Para pensar

> Diseñen una columna nueva que le facilite al árbol entender la noche. Expliquen cómo la calcularían con las columnas existentes y cómo comprobarían, con un número, que de verdad ayudó.

- **Nombre de la columna:** `es_noche`.
- **Cómo la calcularía a partir de las columnas existentes:**

  ```python
  es_noche = ((datos["hora_salida"] <= 5) | (datos["hora_salida"] >= 21)).astype(int)
  ```

- **Por qué le ayuda al árbol:** porque el árbol necesita una sola pregunta (`¿es_noche = 1?`) en lugar de dos cortes sobre la hora.
- **Cómo comprobaría con un número que ayudó:** entrenando el mismo árbol con y sin `es_noche`, con los mismos envíos de prueba (`random_state=42`), y comparando la exactitud.
- **Resultado si lo implementé** (`actividad2_noche.py`):

  | Modelo | Exactitud |
  |---|---|
  | Sin `es_noche` | 92.10 % |
  | Con `es_noche` | 92.95 % |

  Mejoró poco (+0.85 puntos), ya que el árbol ya diferenciaba bien la noche; la columna solo lo hizo más simple.

---

## Actividad 3 — Anatomía de los errores

### Predicción

- **¿Qué confusión será la más frecuente?**
  - **Mi predicción:** creo que sería entre moto y bicicleta.
  - **Por qué lo creo:** si el horario es normal y los kilómetros no son muchos, se pueden llegar a confundir una con otra.
- **¿El modelo confundirá alguna vez una bicicleta con una camioneta?**
  - **Mi predicción:** creo que no, aunque sí podría pasar al revés: que un envío de bicicleta lo mande en camioneta.
  - **Por qué lo creo:** las métricas que menciona el README no hacen posible que un envío se mande en bicicleta cuando debería ir en camioneta.

### Resultado

#### Errores del modelo sobre los 2 000 envíos de prueba

```text
Total de errores: 158
real       predicho 
moto       bicicleta    46
camioneta  moto         32
moto       dron         29
bicicleta  moto         20
dron       bicicleta    18
camioneta  bicicleta     9
           dron          4
```

#### Moto que el modelo mandó a dron

```text
Moto mandada a dron: 29
De noche: 26
Dron imposible (las reglas lo corregirían): 26
Dron posible (las reglas no lo corrigen): 3
      distancia_km  peso_kg  volumen_l  fragil prioridad      clima  hora_salida trafico  valor_declarado_mxn
2484          7.35     1.67       5.72       0   express  despejado 17    alto               388.86
3722         12.14     0.90       3.68       0    normal  despejado 13    alto               455.58
677           7.55     1.05       6.60       0    normal  despejado 18    alto               315.50
```

#### Moto que el modelo mandó a bicicleta

```text
Moto mandada a bicicleta: 46
count    46.00
mean      4.08
std       1.45
min       1.35
25%       2.80
50%       3.88
75%       5.30
max       6.89

                     moto->bici (error)  bici acertadas
distancia_km                       4.08            3.55
peso_kg                            2.37            2.16
volumen_l                          9.96           10.13
hora_salida                       12.98           12.84
valor_declarado_mxn             1897.38         1854.89
fragil                             0.35            0.29

prioridad
           moto->bici (error)  bici acertadas
prioridad                                    
express                  0.30            0.30
mismo_dia                0.48            0.12
normal                   0.22            0.58

clima
               moto->bici (error)  bici acertadas
clima                                            
despejado                    0.52            0.85
lluvia                       0.24            0.02
viento_fuerte                0.24            0.13

trafico
         moto->bici (error)  bici acertadas
trafico                                    
alto                   0.35            0.41
medio                  0.33            0.30
bajo                   0.33            0.29

zona_destino
              moto->bici (error)  bici acertadas
zona_destino                                    
centro                      0.57            0.64
residencial                 0.41            0.35
periferia                   0.02            0.01
```

#### Camioneta real que el modelo mandó a otro medio

```text
Camioneta real mal predicha: 45
Refrigerados: 0
Predicción imposible (las reglas lo corregirían): 3
Predicción posible (las reglas no lo corrigen): 42
```

### Comparación

| | Mi predicción | Resultado real | ¿Acerté? |
|---|---|---|---|
| Confusión más frecuente | moto a bicicleta | moto a bicicleta (46) | Sí |
| ¿Bicicleta confundida con camioneta? | No (camioneta → bicicleta); sí (bicicleta → camioneta) | 9 (camioneta → bicicleta); 0 (bicicleta → camioneta) | No |

- **Qué me sorprendió o por qué fallé:** me sorprendió que sí se confunden camionetas con bicicletas, y en eso fue en lo que fallé. También que al revés (bicicleta → camioneta) no hubo ningún caso.

### Respuestas

#### 3.1 — ¿Cuántos errores hay y cuáles son las tres confusiones más frecuentes? ¿Son entre medios parecidos o muy distintos? ¿Qué me dice eso?

- **Total de errores:** 158.
- **Las tres confusiones más frecuentes:**
  1. moto a bicicleta, con 46.
  2. camioneta a moto, con 32.
  3. moto a dron, con 29.
- **¿Medios parecidos o muy distintos?** Son medios que sí se parecen, ya que son vecinos en capacidad, y la moto es el medio intermedio que aparece en casi todos los errores.
- **Qué me dice eso:** que al modelo le faltan ejemplos y se podrían mejorar algunas reglas, aunque estos errores también se pueden deber al ruido.

#### 3.2 — Envíos que eran moto y el modelo mandó a dron

- **Cuántos son:** 29.
- **Cuántos son de noche:** 26.
- **Cuáles corregirían las reglas del negocio y cuáles no:** las 26 de noche serán corregidas, pero las otras 3 no.
- **Qué tienen en común los que no se corrigen:** todos tienen tráfico alto y clima despejado, pasan los 7 km y son de la tarde.

#### 3.3 — Envíos que eran moto y el modelo mandó a bicicleta

- **¿Están cerca del límite de 7 km?** No. La media es de 4.08 km y solo uno se acerca a los 7 km, con 6.89 km.
- **Qué columnas los distinguen de las bicicletas que el modelo sí acertó:** las columnas categóricas, no las numéricas:
  - **`prioridad`:** `mismo_dia` aparece en 48 % de los errores contra 12 % de las bicicletas acertadas, y `normal` en 22 % contra 58 %.
  - **`clima`:** `lluvia` aparece en 24 % de los errores contra 2 % de las bicicletas acertadas.
  - **Explicación (según el README):** en un envío de `mismo_dia` cada minuto pesa casi siete veces más, y la lluvia y el viento frenan a la bicicleta y a la moto. Entonces, aunque la bicicleta sea posible y barata, un envío urgente o con mal clima suele resolverse con una moto. El modelo se equivoca porque la decisión depende de combinar prioridad con clima, y esa combinación le cuesta aprenderla.

#### 3.4 — ¿Qué pasaría con mi análisis si usara otro `random_state`?

- **Respuesta:** creo que cambiarían un poco los resultados, ya que los datos analizados serían diferentes, pero en esencia la base sería la misma y podría llegar a las mismas conclusiones. Además, el modelo ya habría visto algunos de esos datos al entrenar, por lo que la exactitud saldría inflada.

### Para pensar

> Si solo pudieran arreglar un tipo de error, ¿cuál elegirían y por qué? ¿Lo arreglarían cambiando el modelo, los datos o las reglas del negocio?

- **Error que arreglaría:** los envíos que eran moto y el modelo mandó a dron.
- **Por qué:** porque 26 de los 29 son de noche, una hora en la que el dron no puede volar. Además es un error costoso, porque se sugeriría un medio que no puede operar.
- **Cómo lo arreglaría (modelo, datos o reglas del negocio):** con las reglas del negocio. La función `es_posible` ya descarta al dron de noche, así que aplicarla sobre lo que sugiere el modelo corrige esos 26 casos sin tocar el modelo ni conseguir más datos, y funciona siempre.
