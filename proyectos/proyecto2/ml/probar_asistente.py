"""Prueba el modelo guardado con asistente_prueba.csv o con las frases que pase en la línea de comandos."""

import sys
from pathlib import Path

import joblib
import pandas as pd

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ / "backend"))
from envios.asistente.texto import normalizar  # noqa: E402

MODELO = RAIZ / "backend" / "envios" / "modelo" / "modelo_asistente.joblib"
PRUEBA = RAIZ / "ml" / "datos" / "asistente_prueba.csv"
UMBRALES = (0.0, 0.3, 0.4, 0.5, 0.6)


def predecir(modelo, textos):
    prob = modelo.predict_proba([normalizar(t) for t in textos])
    return modelo.classes_[prob.argmax(axis=1)], prob.max(axis=1)


def main():
    modelo = joblib.load(MODELO)

    if len(sys.argv) > 1:
        textos = sys.argv[1:]
        for texto, intencion, confianza in zip(textos, *predecir(modelo, textos)):
            print(f"{intencion:24} {confianza:.2f}  {texto}")
        return

    datos = pd.read_csv(PRUEBA)
    intenciones, confianzas = predecir(modelo, datos["texto"])
    datos["prediccion"], datos["confianza"] = intenciones, confianzas

    errores = datos[datos["prediccion"] != datos["intencion"]]
    print(f"Exactitud en {len(datos)} frases nuevas: {1 - len(errores) / len(datos):.3f}\n")
    for _, fila in errores.iterrows():
        print(f"{fila['intencion']:24} -> {fila['prediccion']:24} ({fila['confianza']:.2f})  {fila['texto']}")

    print("\numbral | responde | exactitud de lo que responde | no_se bien enviados a no_se")
    for umbral in UMBRALES:
        acepta = datos["confianza"] >= umbral
        exactitud = (datos[acepta]["prediccion"] == datos[acepta]["intencion"]).mean()
        # Lo que queda bajo el umbral lo contesto como no_se.
        final = datos["prediccion"].where(acepta, "no_se")
        total = (final == datos["intencion"]).mean()
        print(f"{umbral:6.2f} | {acepta.mean():8.1%} | {exactitud:28.1%} | exactitud final {total:.1%}")


if __name__ == "__main__":
    main()
