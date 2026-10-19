import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.metrics import precision_score, recall_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
from sklearn.tree import DecisionTreeClassifier
from entrenar_arbol import NUMERICAS, CATEGORICAS, OBJETIVO
from usar_modelo import es_posible

datos = pd.read_csv("envios_medios.csv")
x = datos[NUMERICAS + CATEGORICAS]
y = datos[OBJETIVO]

x_entreno, x_prueba, y_entreno, y_prueba = train_test_split(
    x, y, test_size=0.2, stratify=y, random_state=42
)

def evaluar(nombre, x_ent, y_ent, class_weight=None, x_pru=None, y_pru=None):
    if x_pru is None:
        x_pru, y_pru = x_prueba, y_prueba
    preparacion = ColumnTransformer([
        ("numericas", "passthrough", NUMERICAS),
        ("categoricas", OneHotEncoder(handle_unknown="ignore"), CATEGORICAS),
    ])
    modelo = Pipeline([
        ("preparacion", preparacion),
        ("arbol", DecisionTreeClassifier(
            max_depth=8, min_samples_leaf=5, random_state=42, class_weight=class_weight
        )),
    ])
    modelo.fit(x_ent, y_ent)
    prediccion = modelo.predict(x_pru)

    exactitud = (prediccion == y_pru).mean()
    precision = precision_score(y_pru, prediccion, labels=["dron"], average=None)[0]
    recall = recall_score(y_pru, prediccion, labels=["dron"], average=None)[0]
    veces_dron = (prediccion == "dron").sum()
    imposibles = x_pru.assign(predicho=prediccion).apply(
        lambda fila: not es_posible(fila["predicho"], fila), axis=1
    ).sum()

    print(f"{nombre}: entrenamiento={len(x_ent)}, exactitud={exactitud:.1%}, "
          f"precision dron={precision:.3f}, recall dron={recall:.3f}, "
          f"veces que predice dron={veces_dron}, sugerencias imposibles={imposibles}")

evaluar("Sin balancear", x_entreno, y_entreno)
entreno = x_entreno.copy()
entreno[OBJETIVO] = y_entreno

# 1. Quitar ejemplos de las clases que sobran: todas quedan con tantos como el dron
n_dron = (y_entreno == "dron").sum()
reducido = entreno.groupby(OBJETIVO, group_keys=False).sample(n=n_dron, random_state=42)
evaluar("1. Quitar ejemplos", reducido[x.columns], reducido[OBJETIVO])

# 2. Repetir ejemplos de la clase que falta: todas quedan con tantos como la moto
n_moto = y_entreno.value_counts().max()
partes = [
    entreno[entreno[OBJETIVO] == medio].sample(n=n_moto, replace=True, random_state=42)
    for medio in y_entreno.unique()
]
repetido = pd.concat(partes)
evaluar("2. Repetir ejemplos", repetido[x.columns], repetido[OBJETIVO])

# 4. Decirle al modelo que equivocarse con un dron cuesta más
evaluar("4. class_weight", x_entreno, y_entreno, class_weight="balanced")
extra = pd.read_csv("envios_extra.csv")
extra_dron = extra[extra[OBJETIVO] == "dron"]
x_mas = pd.concat([x_entreno, extra_dron[x.columns]])
y_mas = pd.concat([y_entreno, extra_dron[OBJETIVO]])
evaluar("3. Drones nuevos", x_mas, y_mas)

# TRAMPA a propósito: balancear ANTES de separar (hace lo contrario de A.3)
todo = datos[NUMERICAS + CATEGORICAS + [OBJETIVO]]
n_moto_total = todo[OBJETIVO].value_counts().max()
balanceado = pd.concat([
    todo[todo[OBJETIVO] == medio].sample(n=n_moto_total, replace=True, random_state=42)
    for medio in todo[OBJETIVO].unique()
])
xb = balanceado[x.columns]
yb = balanceado[OBJETIVO]
xb_ent, xb_pru, yb_ent, yb_pru = train_test_split(
    xb, yb, test_size=0.2, stratify=yb, random_state=42
)
evaluar("TRAMPA: balancear antes de separar", xb_ent, yb_ent, x_pru=xb_pru, y_pru=yb_pru)
