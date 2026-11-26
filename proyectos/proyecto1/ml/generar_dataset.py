"""Genera un dataset SINTÉTICO y reproducible de envíos de un vivero.

El etiquetador NO es idéntico a las reglas de negocio y tiene ~5 % de ruido,
para que el árbol no copie las reglas y estas puedan corregirlo.
Uso: python ml/generar_dataset.py  ->  ml/datos/envios_vivero.csv
"""

import csv
import random
from pathlib import Path

SEMILLA = 22121268  # matrícula
FILAS = 9000
PORCENTAJE_RUIDO = 0.05

CARPETA = Path(__file__).resolve().parent
ARCHIVO_SALIDA = CARPETA / "datos" / "envios_vivero.csv"

ENVIOS = ["estandar", "protegido", "humedad", "termico"]

# Peso relativo de cada tipo de planta en los pedidos.
TIPOS_PLANTA = {
    "suculenta": 0.20,
    "interior_tropical": 0.20,
    "exterior": 0.18,
    "frutal": 0.14,
    "hortaliza": 0.16,
    "helecho": 0.12,
}

# Rangos de UNA pieza (cm, kg, MXN) y probabilidad de que sea frágil o vaya a raíz desnuda.
FICHAS = {
    "suculenta":         {"altura": (5, 40),   "maceta": (6, 20),  "peso": (0.2, 1.5),  "precio": (60, 250),   "fragil": 0.15, "raiz": 0.02},
    "interior_tropical": {"altura": (30, 180), "maceta": (12, 35), "peso": (1.0, 9.0),  "precio": (150, 1200), "fragil": 0.45, "raiz": 0.03},
    "exterior":          {"altura": (20, 150), "maceta": (10, 30), "peso": (0.8, 7.0),  "precio": (80, 600),   "fragil": 0.15, "raiz": 0.20},
    "frutal":            {"altura": (40, 200), "maceta": (15, 40), "peso": (2.0, 15.0), "precio": (200, 1500), "fragil": 0.25, "raiz": 0.35},
    "hortaliza":         {"altura": (5, 35),   "maceta": (5, 12),  "peso": (0.1, 0.8),  "precio": (15, 80),    "fragil": 0.35, "raiz": 0.25},
    "helecho":           {"altura": (20, 90),  "maceta": (10, 30), "peso": (0.5, 4.0),  "precio": (100, 500),  "fragil": 0.40, "raiz": 0.10},
}

# Temperatura del destino según la época: (media, desviación).
CLIMA_POR_EPOCA = {
    "primavera": (21, 5),
    "verano": (30, 5),
    "otono": (16, 5),
    "invierno": (8, 6),
}

# Distancia según la zona: (mínimo, máximo) en km.
DISTANCIA_POR_ZONA = {
    "urbana": (2, 40),
    "periferia": (15, 150),
    "rural": (60, 900),
}

SENSIBLES_A_TEMPERATURA = {"interior_tropical", "helecho", "frutal", "hortaliza"}


def elegir(rng, pesos):
    return rng.choices(list(pesos), weights=list(pesos.values()))[0]


def calcular_dias(rng, distancia_km, zona, prioridad):
    """En la app lo captura el usuario; aquí se simula para que el dataset sea coherente."""
    dias = 1 + distancia_km / 250
    if zona == "rural":
        dias += 1
    if prioridad == "express":
        dias -= 1
    dias += rng.uniform(-0.5, 1.0)
    return max(1, min(8, round(dias)))


def generar_pedido(rng):
    tipo = elegir(rng, TIPOS_PLANTA)
    ficha = FICHAS[tipo]
    epoca = rng.choice(list(CLIMA_POR_EPOCA))
    zona = elegir(rng, {"urbana": 0.45, "periferia": 0.30, "rural": 0.25})
    prioridad = elegir(rng, {"normal": 0.75, "express": 0.25})

    # Las hortalizas se venden por charola.
    cantidad = rng.randint(6, 30) if tipo == "hortaliza" else rng.randint(1, 6)

    distancia = round(rng.uniform(*DISTANCIA_POR_ZONA[zona]), 1)
    media, desviacion = CLIMA_POR_EPOCA[epoca]
    temperatura = round(max(-8, min(44, rng.gauss(media, desviacion))), 1)

    return {
        "distancia_km": distancia,
        "peso_kg": round(rng.uniform(*ficha["peso"]) * cantidad, 2),
        "altura_cm": round(rng.uniform(*ficha["altura"]), 1),
        "diametro_maceta_cm": round(rng.uniform(*ficha["maceta"]), 1),
        "cantidad_plantas": cantidad,
        "valor_declarado_mxn": round(rng.uniform(*ficha["precio"]) * cantidad, 2),
        "temperatura_destino_c": temperatura,
        "dias_en_transito": calcular_dias(rng, distancia, zona, prioridad),
        "fragil": int(rng.random() < ficha["fragil"]),
        "raiz_desnuda": int(rng.random() < ficha["raiz"]),
        "tipo_planta": tipo,
        "epoca": epoca,
        "prioridad": prioridad,
        "zona_destino": zona,
    }


def etiquetar(p):
    """Envío que elegiría un encargado del vivero.

    Se parece a las reglas, pero NO es igual (a propósito):
    - manda a `termico` aunque el valor declarado sea menor a 150 MXN;
    - manda a `humedad` sin fijarse en que la planta mida más de 120 cm;
    - acepta `estandar` hasta 4 días para suculentas y plantas de exterior
      (la regla corta en 3);
    - usa umbrales de temperatura un poco distintos a los de las reglas.
    """
    tipo = p["tipo_planta"]
    temperatura = p["temperatura_destino_c"]
    dias = p["dias_en_transito"]

    # 1) Clima extremo.
    extremo_para_sensible = tipo in SENSIBLES_A_TEMPERATURA and (temperatura < 4 or temperatura > 34)
    extremo_para_todas = temperatura < 0 or temperatura > 38
    if (extremo_para_sensible or extremo_para_todas) and dias <= 5:
        return "termico"

    # 2) Raíz expuesta o plantas que se deshidratan rápido (nunca suculentas).
    if tipo != "suculenta":
        if p["raiz_desnuda"] or tipo == "helecho":
            return "humedad"
        if tipo == "interior_tropical" and dias >= 3:
            return "humedad"
        if temperatura > 30 and dias >= 2:
            return "humedad"

    # 3) Piezas delicadas, altas o caras.
    if p["fragil"] or p["altura_cm"] > 90 or p["valor_declarado_mxn"] > 2500:
        return "protegido"

    # 4) Lo demás, en caja normal si el trayecto es corto.
    limite_dias = 4 if tipo in {"suculenta", "exterior"} else 3
    if dias <= limite_dias:
        return "estandar"
    return "protegido"


def main():
    rng = random.Random(SEMILLA)
    filas = []
    for numero in range(1, FILAS + 1):
        pedido = generar_pedido(rng)
        envio = etiquetar(pedido)
        # Ruido: a veces la persona se equivoca.
        if rng.random() < PORCENTAJE_RUIDO:
            envio = rng.choice([e for e in ENVIOS if e != envio])
        filas.append({"id_envio": f"VIV-{numero:06d}", **pedido, "envio_recomendado": envio})

    ARCHIVO_SALIDA.parent.mkdir(parents=True, exist_ok=True)
    with open(ARCHIVO_SALIDA, "w", newline="", encoding="utf-8") as archivo:
        escritor = csv.DictWriter(archivo, fieldnames=list(filas[0]))
        escritor.writeheader()
        escritor.writerows(filas)

    print(f"{len(filas)} filas guardadas en {ARCHIVO_SALIDA}")
    for envio in ENVIOS:
        total = sum(f["envio_recomendado"] == envio for f in filas)
        print(f"  {envio:<10} {total:>5}  ({total / len(filas):.1%})")


if __name__ == "__main__":
    main()
