"""Adapter: traduce las probabilidades de scikit-learn a una Sugerencia."""

from abc import ABC, abstractmethod
from dataclasses import asdict, dataclass, field
from functools import lru_cache
from pathlib import Path

import joblib
import pandas as pd

from .reglas import ENVIO_RESPALDO, ENVIOS, motivo_descarte

RUTA_MODELO = Path(__file__).resolve().parent / "modelo" / "modelo_vivero.joblib"

# Mantengo estas columnas iguales a las de ml/entrenar_modelo.py.
CAMPOS_NUMERICOS = [
    "distancia_km", "peso_kg", "altura_cm", "diametro_maceta_cm", "cantidad_plantas",
    "valor_declarado_mxn", "temperatura_destino_c", "dias_en_transito",
    "fragil", "raiz_desnuda",
]
CAMPOS_TEXTO = ["tipo_planta", "epoca", "prioridad", "zona_destino"]
CAMPOS = CAMPOS_NUMERICOS + CAMPOS_TEXTO


@dataclass(frozen=True)
class Sugerencia:
    envio: str
    confianza: float
    preferido_por_modelo: str
    corregido_por_reglas: bool
    motivo: str
    ranking: list = field(default_factory=list)
    descartados: list = field(default_factory=list)
    sin_opcion_valida: bool = False

    def a_dict(self):
        return asdict(self)


class RecomendadorIA(ABC):
    @abstractmethod
    def sugerir(self, paquete: dict) -> Sugerencia:
        pass


class RecomendadorArbol(RecomendadorIA):
    def __init__(self, ruta=RUTA_MODELO):
        self._modelo = joblib.load(ruta)

    def sugerir(self, paquete):
        datos = pd.DataFrame([paquete], columns=CAMPOS)
        probabilidades = self._modelo.predict_proba(datos)[0]
        ordenado = sorted(zip(self._modelo.classes_, probabilidades), key=lambda par: -par[1])
        preferido = str(ordenado[0][0])

        # Evalúo los cuatro envíos para poder mostrar por qué se descartó cada uno.
        motivos = {envio: motivo_descarte(envio, paquete) for envio in ENVIOS}
        ranking = [
            {"envio": str(envio), "probabilidad": round(float(p), 3), "posible": motivos[envio] is None}
            for envio, p in ordenado
        ]
        descartados = [{"envio": e, "motivo": m} for e, m in motivos.items() if m is not None]

        for opcion in ranking:
            if opcion["posible"]:
                envio = opcion["envio"]
                motivo = f"árbol de decisión, confianza {opcion['probabilidad']:.0%}"
                if envio != preferido:
                    motivo += f"; se descartó {preferido} porque {motivos[preferido]}"
                return Sugerencia(
                    envio=envio,
                    confianza=opcion["probabilidad"],
                    preferido_por_modelo=preferido,
                    corregido_por_reglas=envio != preferido,
                    motivo=motivo,
                    ranking=ranking,
                    descartados=descartados,
                )

        # Con confianza 0 aviso que no fue decisión del modelo.
        return Sugerencia(
            envio=ENVIO_RESPALDO,
            confianza=0.0,
            preferido_por_modelo=preferido,
            corregido_por_reglas=True,
            motivo=(f"ningún envío cumple las reglas; se usa {ENVIO_RESPALDO} como respaldo "
                    "y conviene revisar el pedido con el encargado del vivero"),
            ranking=ranking,
            descartados=descartados,
            sin_opcion_valida=True,
        )


@lru_cache(maxsize=1)
def obtener_recomendador() -> RecomendadorIA:
    # Cargo el .joblib una sola vez por proceso.
    return RecomendadorArbol()
