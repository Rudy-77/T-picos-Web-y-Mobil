import pandas as pd
from entrenar_arbol import NUMERICAS, CATEGORICAS, OBJETIVO
from usar_modelo import LIMITES, es_posible

pd.set_option("display.width", 200)

datos = pd.read_csv("envios_medios.csv")

print(datos.shape)

print("\n== Dominio por clima (% por fila) ==")
tabla_clima = pd.crosstab(datos["clima"], datos["medio_recomendado"], normalize="index")
print((tabla_clima*100).round(1))

print("\n== Dominio por zona (% por fila) ==")
tabla_zona = pd.crosstab(datos["zona_destino"], datos["medio_recomendado"], normalize="index")
print((tabla_zona*100).round(1))

print(datos.head())