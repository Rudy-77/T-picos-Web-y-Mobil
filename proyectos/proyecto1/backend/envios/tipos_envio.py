"""Patrón Strategy: una clase por tipo de envío, todas con `planear(paquete)`.

Agregar un envío es agregar una clase y registrarla en TIPOS_ENVIO, sin tocar las vistas.
"""

from abc import ABC, abstractmethod


def costo_estimado(paquete, base, por_kg, por_km):
    costo = base + por_kg * paquete["peso_kg"] + por_km * paquete["distancia_km"]
    if paquete["prioridad"] == "express":
        costo *= 1.3
    return round(costo, 2)


def riego_sugerido(paquete):
    """Cómo regar antes de empacar y al recibir, según la planta y el destino."""
    tipo = paquete["tipo_planta"]
    if paquete["raiz_desnuda"]:
        texto = "Hidratar la raíz 2 h en agua antes de empacar; al recibirla, plantar y regar abundante."
    elif tipo == "suculenta":
        texto = "No regar antes del envío (el sustrato seco evita pudrición); regar ligero 2 o 3 días después de recibirla."
    elif tipo in ("interior_tropical", "helecho"):
        texto = "Regar 24 h antes de empacar; al llegar, rociar las hojas y regar si el sustrato está seco."
    elif tipo == "hortaliza":
        texto = "Regar la charola la mañana del envío; al llegar, regar a diario la primera semana."
    else:
        texto = "Regar el día anterior al envío; al recibir, regar cuando los primeros 2 cm de sustrato estén secos."

    if paquete["temperatura_destino_c"] > 30:
        texto += " Por el calor del destino, regar al atardecer."
    return texto


class TipoEnvio(ABC):
    @abstractmethod
    def planear(self, paquete: dict) -> dict:
        pass


class EnvioEstandar(TipoEnvio):
    def planear(self, paquete):
        return {
            "envio": "estandar",
            "empaque": "caja de cartón con separadores",
            "dias": paquete["dias_en_transito"],
            "costo_estimado_mxn": costo_estimado(paquete, base=90, por_kg=8, por_km=0.15),
            "indicacion": "mantener la caja en posición vertical",
            "riego_sugerido": riego_sugerido(paquete),
        }


class EnvioProtegido(TipoEnvio):
    def planear(self, paquete):
        return {
            "envio": "protegido",
            "empaque": "caja reforzada con relleno y tutor para el tallo",
            "dias": paquete["dias_en_transito"],
            "costo_estimado_mxn": costo_estimado(paquete, base=150, por_kg=10, por_km=0.18),
            "indicacion": "frágil: no apilar y manejar con cuidado",
            "riego_sugerido": riego_sugerido(paquete),
        }


class EnvioHumedad(TipoEnvio):
    def planear(self, paquete):
        return {
            "envio": "humedad",
            "empaque": "bolsa con sustrato húmedo o musgo dentro de caja ventilada",
            "dias": paquete["dias_en_transito"],
            "costo_estimado_mxn": costo_estimado(paquete, base=130, por_kg=9, por_km=0.17),
            "indicacion": "abrir al recibir; el empaque ya retiene humedad, no regar de más antes de cerrarlo",
            "riego_sugerido": riego_sugerido(paquete),
        }


class EnvioTermico(TipoEnvio):
    def planear(self, paquete):
        if paquete["temperatura_destino_c"] < 10:
            indicacion = "caja aislada con gel térmico caliente: proteger del frío"
        elif paquete["temperatura_destino_c"] > 28:
            indicacion = "caja aislada con gel refrigerante: proteger del calor"
        else:
            indicacion = "caja aislada: mantener la temperatura estable durante el tránsito"
        return {
            "envio": "termico",
            "empaque": "caja de unicel con gel térmico",
            "dias": paquete["dias_en_transito"],
            "costo_estimado_mxn": costo_estimado(paquete, base=260, por_kg=12, por_km=0.25),
            "indicacion": indicacion,
            "riego_sugerido": riego_sugerido(paquete),
        }


TIPOS_ENVIO = {
    "estandar": EnvioEstandar,
    "protegido": EnvioProtegido,
    "humedad": EnvioHumedad,
    "termico": EnvioTermico,
}


def crear_tipo_envio(nombre: str) -> TipoEnvio:
    return TIPOS_ENVIO[nombre]()
