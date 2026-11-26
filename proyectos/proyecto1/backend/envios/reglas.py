"""Reglas del negocio que el modelo NO puede saltarse.

Si una regla descarta un envío, se descarta aunque el modelo tenga mucha confianza.
"""

ENVIOS = ["estandar", "protegido", "humedad", "termico"]

# Si ningún envío es posible se usa el térmico (el más controlado) y se avisa.
ENVIO_RESPALDO = "termico"

# Una llave ausente significa "sin límite".
LIMITES = {
    "estandar": {"temperatura_min_c": 5, "temperatura_max_c": 35, "dias_max": 3},
    "protegido": {"temperatura_min_c": 0, "temperatura_max_c": 38},
    "humedad": {"temperatura_min_c": 3, "altura_max_cm": 120},
    "termico": {"dias_max": 5, "valor_min_mxn": 150},
}

DIAS_MAX_RAIZ_DESNUDA_PROTEGIDO = 2


def motivo_descarte(envio, paquete):
    """Devuelve por qué `envio` NO es posible para `paquete`, o None si sí lo es."""
    limite = LIMITES[envio]
    temperatura = paquete["temperatura_destino_c"]
    dias = paquete["dias_en_transito"]

    if "temperatura_min_c" in limite and temperatura < limite["temperatura_min_c"]:
        return f"la temperatura del destino ({temperatura} °C) es menor a {limite['temperatura_min_c']} °C"
    if "temperatura_max_c" in limite and temperatura > limite["temperatura_max_c"]:
        return f"la temperatura del destino ({temperatura} °C) es mayor a {limite['temperatura_max_c']} °C"
    if "dias_max" in limite and dias > limite["dias_max"]:
        return f"el tránsito ({dias} días) supera el máximo de {limite['dias_max']} días"
    if "altura_max_cm" in limite and paquete["altura_cm"] > limite["altura_max_cm"]:
        return f"la planta mide {paquete['altura_cm']} cm y el empaque admite hasta {limite['altura_max_cm']} cm"
    if "valor_min_mxn" in limite and paquete["valor_declarado_mxn"] < limite["valor_min_mxn"]:
        return f"el valor declarado ({paquete['valor_declarado_mxn']} MXN) no justifica el costo (mínimo {limite['valor_min_mxn']} MXN)"

    if envio == "estandar" and paquete["raiz_desnuda"]:
        return "una planta a raíz desnuda no puede viajar en caja estándar"
    if envio == "protegido" and paquete["raiz_desnuda"] and dias > DIAS_MAX_RAIZ_DESNUDA_PROTEGIDO:
        return f"a raíz desnuda, la caja protegida solo aguanta {DIAS_MAX_RAIZ_DESNUDA_PROTEGIDO} días"
    if envio == "humedad" and paquete["tipo_planta"] == "suculenta":
        return "la humedad pudre las suculentas"
    return None


def es_posible(envio, paquete):
    return motivo_descarte(envio, paquete) is None
