# Análisis del dataset de envíos

## Actividad 1 — El retrato del dataset

### Predicción

| # | Pregunta | Predicción y razón |
|---|----------|--------------------|
| 1 | Cuando llueve, ¿qué medio domina? | **Camioneta**, porque asi tanto los paquetes como el conductor se resguardan de posbles daños |
| 2 | En el centro de la ciudad, ¿qué medio domina? | **Bicicleta o moto**, porque ya que es mas practico para evitar el trafico, la desisicion dependeria del volumen del paquete |
| 3 | ¿Cuál es la distancia más larga que recorre una bicicleta? | **Aprox. 7 km**, porque una persona en bicicleta tardaria demasiado a mas de esa distancia ademas de que no puede llevar paquetes demasiado grandes |
| 4 | ¿Cuántos envíos tienen una etiqueta que rompe las reglas del negocio? | **0**, porque se supone que el model siempre sigue as reglas y si algo no encaja al 100% lo envia al valor mas cercano |

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

---

### Comparación

#### Predicción 1 — Medio dominante cuando llueve

- **Predije:** que en lluvia la mejor opcion seria la camioneta.
- **El resultado fue:** moto 74.8%.
- **Fallé** porque la camioneta solo tiene 16.7% de ser elegida.
- **Lo que no había considerado:** me fui por la facil de la proteccion del paquete pero el modelo no toma en cuenta eso si no que medio es mas barato para trasportar por lo que viendolo asi tiene sentido que sea la moto y la camioneta solo se usaria en paquetes grandes.

#### Predicción 2 — Medio dominante en el centro

- **Predije:** que en el centro la mejor opcion seria moto o bicicleta.
- **El resultado fue:** bicicleta 58.4% y moto con 28%.
- **Acerté** porque son los dos medios con mayor probabildad de ser selecionados por el modelo si el paquete es al centro.
- **Lo que no había considerado:** si el paquete es refigerador tiene que ser camioneta si o si por lo que no se puede descartar que sean camionetas.
