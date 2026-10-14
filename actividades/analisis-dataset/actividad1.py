import pandas as pd
from entrenar_arbol import NUMERICAS, CATEGORICAS, OBJETIVO
from usar_modelo import LIMITES, es_posible

pd.set_option("display.width", 200)
pd.set_option("display.max_columns", None)

datos = pd.read_csv("envios_medios.csv")

print(datos.shape)

print("\n== Dominio por clima (% por fila) ==")
tabla_clima = pd.crosstab(datos["clima"], datos["medio_recomendado"], normalize="index")
print((tabla_clima*100).round(1))

print("\n== Dominio por zona (% por fila) ==")
tabla_zona = pd.crosstab(datos["zona_destino"], datos["medio_recomendado"], normalize="index")
print((tabla_zona*100).round(1))

print ("\n== Resumen por medio ==")
resumen = datos.groupby("medio_recomendado")[["distancia_km", "peso_kg", "volumen_l"]].agg(["min", "median", "max"])
print (resumen.round(2))

print("\n== Etiquetas que rompen las reglas==")
posibles = datos.apply(lambda fila: es_posible(fila["medio_recomendado"], fila), axis=1)
print ("Etiquetas imposibles", (~posibles).sum())
print (datos[~posibles][["id_envio", "medio_recomendado"]].head())

print("\n== Distancia por zona ==")
print(datos.groupby("zona_destino")["distancia_km"].agg(["min", "median", "max"]).round(2).to_string())

print("\n== Camionetas con distancia < 2 km ==")
cortas = datos[(datos["medio_recomendado"] == "camioneta") & (datos["distancia_km"] < 2)]
print("Total:", len(cortas))

razon_clara = (
    (cortas["refrigerado"] == 1)
    | (cortas["peso_kg"] > LIMITES["moto"]["peso_kg"])
    | (cortas["volumen_l"] > LIMITES["moto"]["volumen_l"])
)
print("Con razón clara:", razon_clara.sum())
print("Sin razón clara:", (~razon_clara).sum())

sin_razon = cortas[~razon_clara]
print(sin_razon[["distancia_km", "peso_kg", "volumen_l", "fragil", "prioridad", "trafico", "clima", "valor_declarado_mxn"]].head(12).to_string())

print(datos.head())