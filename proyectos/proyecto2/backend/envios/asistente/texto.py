"""Funciones puras de texto (sin Django): las usan el entrenamiento y el servidor."""

import re

TOKEN_FOLIO = "tokenfolio"

# Acepto formas como VIV-20261123-0001, viv 20261123 0001 o VIV202611230001.
PATRON_FOLIO = re.compile(r"\bviv[\s\-_]*(\d{8})[\s\-_]*(\d{1,4})\b", re.IGNORECASE)


def extraer_folio(texto):
    """Devuelve el primer folio del texto en formato VIV-AAAAMMDD-0001, o None."""
    encontrado = PATRON_FOLIO.search(texto or "")
    if encontrado is None:
        return None
    return f"VIV-{encontrado.group(1)}-{int(encontrado.group(2)):04d}"


def normalizar(texto):
    """Cambia el folio por un token para que el modelo no dependa de los dígitos."""
    return PATRON_FOLIO.sub(f" {TOKEN_FOLIO} ", texto or "").strip()
