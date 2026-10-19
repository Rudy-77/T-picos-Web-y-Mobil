import joblib
import pandas as pd
from entrenar_arbol import CATEGORICAS

modelo = joblib.load("modelo_medios.joblib")

nombres = modelo.named_steps["preparacion"].get_feature_names_out()
importancias = modelo.named_steps["arbol"].feature_importances_
tabla = pd.Series(importancias, index=nombres).sort_values(ascending=False)

def columna_original(nombre):
    nombre = nombre.split("__", 1)[1]
    for columna in CATEGORICAS:
        if nombre.startswith(columna + "_"):
            return columna
    return nombre

por_columna = tabla.groupby(columna_original).sum().sort_values(ascending=False)
print((por_columna * 100).round(2).to_string())
from sklearn.compose import ColumnTransformer
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
from sklearn.tree import DecisionTreeClassifier
from entrenar_arbol import NUMERICAS, CATEGORICAS, OBJETIVO

datos = pd.read_csv("envios_medios.csv")

def exactitud(numericas, categoricas):
    x = datos[numericas + categoricas]
    y = datos[OBJETIVO]
    x_entreno, x_prueba, y_entreno, y_prueba = train_test_split(
        x, y, test_size=0.2, stratify=y, random_state=42
    )
    preparacion = ColumnTransformer([
        ("numericas", "passthrough", numericas),
        ("categoricas", OneHotEncoder(handle_unknown="ignore"), categoricas),
    ])
    modelo = Pipeline([
        ("preparacion", preparacion),
        ("arbol", DecisionTreeClassifier(max_depth=8, min_samples_leaf=5, random_state=42)),
    ])
    modelo.fit(x_entreno, y_entreno)
    return (modelo.predict(x_prueba) == y_prueba).mean()

base = exactitud(NUMERICAS, CATEGORICAS)
print("\nCon todas las columnas:", round(base * 100, 2), "%")

resultados = {}
for col in NUMERICAS:
    resultados[col] = exactitud([c for c in NUMERICAS if c != col], CATEGORICAS)
for col in CATEGORICAS:
    resultados[col] = exactitud(NUMERICAS, [c for c in CATEGORICAS if c != col])

cambio = (pd.Series(resultados) - base) * 100
print(cambio.sort_values().round(2).to_string())