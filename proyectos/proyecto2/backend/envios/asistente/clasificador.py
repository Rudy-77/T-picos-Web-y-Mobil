"""Adapter: traduce las probabilidades de scikit-learn a una Intencion."""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

import joblib

from .texto import normalizar

RUTA_MODELO = Path(__file__).resolve().parent.parent / "modelo" / "modelo_asistente.joblib"


@dataclass(frozen=True)
class Intencion:
    nombre: str
    confianza: float


class ClasificadorIntenciones(ABC):
    @abstractmethod
    def clasificar(self, texto: str) -> Intencion:
        pass


class ClasificadorTfidf(ClasificadorIntenciones):
    def __init__(self, ruta=RUTA_MODELO):
        self._modelo = joblib.load(ruta)

    def clasificar(self, texto):
        probabilidades = self._modelo.predict_proba([normalizar(texto)])[0]
        mejor = probabilidades.argmax()
        return Intencion(str(self._modelo.classes_[mejor]), round(float(probabilidades[mejor]), 3))


@lru_cache(maxsize=1)
def obtener_clasificador() -> ClasificadorIntenciones:
    # Cargo el .joblib en la primera pregunta y una sola vez por proceso.
    return ClasificadorTfidf()
