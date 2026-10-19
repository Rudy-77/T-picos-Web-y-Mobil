import joblib
import pandas as pd
from sklearn.model_selection import train_test_split
from entrenar_arbol import NUMERICAS, CATEGORICAS, OBJETIVO
from usar_modelo import es_posible

pd.set_option("display.width", 200)
pd.set_option("display.max_columns", None)

datos = pd.read_csv("envios_medios.csv")
x = datos[NUMERICAS + CATEGORICAS]
y = datos[OBJETIVO]

x_entreno, x_prueba, y_entreno, y_prueba = train_test_split(
    x, y, test_size=0.2, stratify=y, random_state=42
)

modelo = joblib.load("modelo_medios.joblib")
prediccion = modelo.predict(x_prueba)

resultados = x_prueba.assign(real=y_prueba, predicho=prediccion)
errores = resultados[resultados["real"] != resultados["predicho"]]

print("Total de errores:", len(errores))
print(errores.groupby(["real", "predicho"]).size().sort_values(ascending=False).to_string())

moto_a_dron = errores[(errores["real"] == "moto") & (errores["predicho"] == "dron")]
print("\nMoto mandada a dron:", len(moto_a_dron))

de_noche = (moto_a_dron["hora_salida"] < 6) | (moto_a_dron["hora_salida"] >= 21)
print("De noche:", de_noche.sum())

dron_posible = moto_a_dron.apply(lambda fila: es_posible("dron", fila), axis=1)
print("Dron imposible (las reglas lo corregirían):", (~dron_posible).sum())
print("Dron posible (las reglas no lo corrigen):", dron_posible.sum())

print(moto_a_dron[dron_posible][["distancia_km", "peso_kg", "volumen_l", "fragil", "prioridad", "clima", "hora_salida", "trafico", "valor_declarado_mxn"]].to_string())

moto_a_bici = errores[(errores["real"] == "moto") & (errores["predicho"] == "bicicleta")]
print("\nMoto mandada a bicicleta:", len(moto_a_bici))
print(moto_a_bici["distancia_km"].describe().round(2).to_string())

bici_acertadas = resultados[(resultados["real"] == "bicicleta") & (resultados["predicho"] == "bicicleta")]

columnas = ["distancia_km", "peso_kg", "volumen_l", "hora_salida", "valor_declarado_mxn", "fragil"]
comparacion = pd.DataFrame({
    "moto->bici (error)": moto_a_bici[columnas].mean(),
    "bici acertadas": bici_acertadas[columnas].mean(),
}).round(2)
print("\n" + comparacion.to_string())

for col in ["prioridad", "clima", "trafico", "zona_destino"]:
    tabla = pd.DataFrame({
        "moto->bici (error)": moto_a_bici[col].value_counts(normalize=True),
        "bici acertadas": bici_acertadas[col].value_counts(normalize=True),
    }).round(2).fillna(0)
    print("\n" + col)
    print(tabla.to_string())
    camioneta_mal = errores[errores["real"] == "camioneta"]
