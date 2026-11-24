"""Entrena el clasificador de intenciones del asistente y guarda el .joblib (se corre fuera de Django)."""

import sys
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import cross_val_predict, train_test_split
from sklearn.pipeline import FeatureUnion, Pipeline

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ / "backend"))
from envios.asistente.texto import normalizar  # noqa: E402

DATOS = RAIZ / "ml" / "datos" / "asistente_intenciones.csv"
PRUEBA = RAIZ / "ml" / "datos" / "asistente_prueba.csv"
SALIDA = RAIZ / "backend" / "envios" / "modelo" / "modelo_asistente.joblib"


def crear_modelo():
    # Uso palabras y caracteres: los n-gramas de caracteres absorben faltas como "grax" o "holaa".
    # C=10 lo elegí con validación cruzada (con C=1 las probabilidades salen muy planas).
    vectores = FeatureUnion([
        ("palabras", TfidfVectorizer(ngram_range=(1, 2), strip_accents="unicode")),
        ("caracteres", TfidfVectorizer(analyzer="char_wb", ngram_range=(2, 4), strip_accents="unicode")),
    ])
    return Pipeline([("tfidf", vectores), ("clf", LogisticRegression(C=10, max_iter=2000))])


def tabla_umbrales(modelo, textos, etiquetas):
    """Validación cruzada sobre el entrenamiento: aciertos y cobertura por umbral."""
    prob = cross_val_predict(modelo, textos, etiquetas, cv=5, method="predict_proba")
    clases = np.unique(etiquetas)
    prediccion = clases[prob.argmax(axis=1)]
    confianza = prob.max(axis=1)
    print("\numbral | responde | exactitud de lo que responde")
    for umbral in (0.0, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7):
        acepta = confianza >= umbral
        exactitud = (prediccion[acepta] == np.asarray(etiquetas)[acepta]).mean()
        print(f"{umbral:6.2f} | {acepta.mean():8.1%} | {exactitud:.1%}")


def main():
    datos = pd.read_csv(DATOS)
    x = datos["texto"].map(normalizar)
    y = datos["intencion"]
    x_ent, x_test, y_ent, y_test = train_test_split(
        x, y, test_size=0.25, random_state=42, stratify=y
    )

    modelo = crear_modelo().fit(x_ent, y_ent)
    prediccion = modelo.predict(x_test)
    print(f"Partición 75/25 ({len(x_ent)} entrenamiento, {len(x_test)} prueba)")
    print(f"Exactitud: {accuracy_score(y_test, prediccion):.3f}\n")
    print(classification_report(y_test, prediccion, zero_division=0))

    tabla_umbrales(crear_modelo(), x_ent, y_ent)

    aparte = pd.read_csv(PRUEBA)
    pred_aparte = modelo.predict(aparte["texto"].map(normalizar))
    print(f"\nFrases nuevas escritas a mano ({len(aparte)}): "
          f"exactitud {accuracy_score(aparte['intencion'], pred_aparte):.3f}")

    # El modelo final lo reentreno con todo el dataset; la partición solo me sirvió para medir.
    final = crear_modelo().fit(x, y)
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(final, SALIDA)
    print(f"\nModelo guardado en {SALIDA.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
