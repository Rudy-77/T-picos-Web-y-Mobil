import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
from sklearn.tree import DecisionTreeClassifier
from entrenar_arbol import NUMERICAS, CATEGORICAS, OBJETIVO

datos = pd.read_csv("envios_medios.csv")
datos["es_noche"] = ((datos["hora_salida"] <= 5) | (datos["hora_salida"] >= 21)).astype(int)

def evaluar(numericas):
    x = datos[numericas + CATEGORICAS]
    y = datos[OBJETIVO]
    x_entreno, x_prueba, y_entreno, y_prueba = train_test_split(
        x, y, test_size=0.2, stratify=y, random_state=42
    )
    preparacion = ColumnTransformer([
        ("numericas", "passthrough", numericas),
        ("categoricas", OneHotEncoder(handle_unknown="ignore"), CATEGORICAS),
    ])
    modelo = Pipeline([
        ("preparacion", preparacion),
        ("arbol", DecisionTreeClassifier(max_depth=8, min_samples_leaf=5, random_state=42)),
    ])
    modelo.fit(x_entreno, y_entreno)
    prediccion = modelo.predict(x_prueba)
    return (prediccion == y_prueba).mean()

print("Sin es_noche:", round(evaluar(NUMERICAS) * 100, 2), "%")
print("Con es_noche:", round(evaluar(NUMERICAS + ["es_noche"]) * 100, 2), "%")