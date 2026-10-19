import pandas as pd
pd.set_option("display.width", 200)
pd.set_option("display.max_columns", None)

#Envios X Hora y Medio
datos = pd.read_csv("envios_medios.csv")
tabla = pd.crosstab(datos["hora_salida"], datos["medio_recomendado"])
es_noche = (datos["hora_salida"] < 6) | (datos["hora_salida"] >= 21)
print(tabla.to_string())

#Noche
print("Envíos de noche:", es_noche.sum())
print("Envíos de día:", (~es_noche).sum())
print("Porcentaje de noche:", round(es_noche.mean() * 100, 2), "%")

#Grafica
grafica = tabla.plot(kind="bar", stacked=True, figsize=(12, 6))
grafica.set_title("Envíos por hora y medio")
grafica.set_xlabel("Hora de salida")
grafica.set_ylabel("Número de envíos")
grafica.figure.tight_layout()
grafica.figure.savefig("horas.png")