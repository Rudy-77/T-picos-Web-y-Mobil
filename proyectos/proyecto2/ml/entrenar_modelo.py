"""Entrena el árbol de decisión del vivero y lo guarda como .joblib (adaptado del curso)."""

from pathlib import Path

import joblib
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
from sklearn.tree import DecisionTreeClassifier, export_text

CARPETA = Path(__file__).resolve().parent
ARCHIVO_DATOS = CARPETA / "datos" / "envios_vivero.csv"
ARCHIVO_MODELO = CARPETA.parent / "backend" / "envios" / "modelo" / "modelo_vivero.joblib"

NUMERICAS = [
    "distancia_km", "peso_kg", "altura_cm", "diametro_maceta_cm", "cantidad_plantas",
    "valor_declarado_mxn", "temperatura_destino_c", "dias_en_transito",
    "fragil", "raiz_desnuda",
]
CATEGORICAS = ["tipo_planta", "epoca", "prioridad", "zona_destino"]
OBJETIVO = "envio_recomendado"

datos = pd.read_csv(ARCHIVO_DATOS)

x = datos[NUMERICAS + CATEGORICAS]
y = datos[OBJETIVO]

# Con stratify conservo la proporción de clases (termico es la menos frecuente).
x_entreno, x_prueba, y_entreno, y_prueba = train_test_split(
    x, y, test_size=0.2, stratify=y, random_state=42
)

preparacion = ColumnTransformer([
    ("numericas", "passthrough", NUMERICAS),
    ("categoricas", OneHotEncoder(handle_unknown="ignore"), CATEGORICAS),
])

# Limito la profundidad y pido hojas de al menos 5 casos para no memorizar el ruido.
modelo = Pipeline([
    ("preparacion", preparacion),
    ("arbol", DecisionTreeClassifier(max_depth=8, min_samples_leaf=5, random_state=42)),
])

modelo.fit(x_entreno, y_entreno)

prediccion = modelo.predict(x_prueba)
print(f"Filas: {len(datos)} (entrenamiento {len(x_entreno)}, prueba {len(x_prueba)})")
print(f"Exactitud: {(prediccion == y_prueba).mean():.1%}")
print(classification_report(y_prueba, prediccion, digits=3))

etiquetas = sorted(y.unique())
print("Matriz de confusión (filas = etiqueta real, columnas = predicción):")
print(pd.DataFrame(
    confusion_matrix(y_prueba, prediccion, labels=etiquetas),
    index=etiquetas, columns=etiquetas,
))

nombres = [n.split("__", 1)[1] for n in modelo.named_steps["preparacion"].get_feature_names_out()]
print(export_text(modelo.named_steps["arbol"], feature_names=nombres, max_depth=3))

ARCHIVO_MODELO.parent.mkdir(parents=True, exist_ok=True)
joblib.dump(modelo, ARCHIVO_MODELO)
print(f"Modelo guardado en {ARCHIVO_MODELO}")
