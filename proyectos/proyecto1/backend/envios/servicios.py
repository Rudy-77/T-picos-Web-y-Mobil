"""Facade: una sola entrada para recomendar y registrar pedidos.

Coordina validación, recomendador (Adapter), tipo de envío (Strategy) y
repositorio. Todo se calcula en el servidor; no se confía en el cliente.
"""

import math

from .recomendador import CAMPOS_NUMERICOS, obtener_recomendador
from .repositorios import PedidoRepositorio, ProductoRepositorio
from .tipos_envio import crear_tipo_envio

# El OneHotEncoder ignoraría en silencio un valor desconocido; por eso se rechaza aquí.
OPCIONES = {
    "tipo_planta": ["suculenta", "interior_tropical", "exterior", "frutal", "hortaliza", "helecho"],
    "epoca": ["primavera", "verano", "otono", "invierno"],
    "prioridad": ["normal", "express"],
    "zona_destino": ["urbana", "periferia", "rural"],
}
BINARIOS = ["fragil", "raiz_desnuda"]
ENTEROS = ["cantidad_plantas", "dias_en_transito"]

# Rangos aceptados (mínimo, máximo). El diámetro puede ser 0 porque una
# planta a raíz desnuda no lleva maceta.
RANGOS = {
    "distancia_km": (0.1, 5000),
    "peso_kg": (0.01, 1000),
    "altura_cm": (1, 500),
    "diametro_maceta_cm": (0, 200),
    "cantidad_plantas": (1, 1000),
    "valor_declarado_mxn": (0, 1_000_000),
    "temperatura_destino_c": (-30, 55),
    "dias_en_transito": (1, 30),
}


class ErrorDeEntrada(Exception):
    def __init__(self, mensaje, campos=None):
        super().__init__(mensaje)
        self.mensaje = mensaje
        self.campos = campos or []

    def a_dict(self):
        datos = {"error": self.mensaje}
        if self.campos:
            datos["campos"] = self.campos
        return datos


def leer_caracteristicas(datos):
    """Valida y normaliza las 14 características. Lanza ErrorDeEntrada."""
    if not isinstance(datos, dict):
        raise ErrorDeEntrada("el cuerpo debe ser un objeto JSON")

    faltantes = [c for c in CAMPOS_NUMERICOS + list(OPCIONES) if c not in datos]
    if faltantes:
        raise ErrorDeEntrada("faltan campos", faltantes)

    paquete = {}
    for campo in CAMPOS_NUMERICOS:
        valor = datos[campo]
        if isinstance(valor, bool):
            valor = int(valor)
        try:
            numero = float(valor)
        except (TypeError, ValueError):
            raise ErrorDeEntrada(f"el campo {campo} debe ser un número", [campo])
        if not math.isfinite(numero):
            raise ErrorDeEntrada(f"el campo {campo} debe ser un número finito", [campo])

        if campo in BINARIOS:
            if numero not in (0, 1):
                raise ErrorDeEntrada(f"el campo {campo} debe ser 0 o 1", [campo])
            paquete[campo] = int(numero)
            continue

        minimo, maximo = RANGOS[campo]
        if not minimo <= numero <= maximo:
            raise ErrorDeEntrada(f"el campo {campo} debe estar entre {minimo} y {maximo}", [campo])
        if campo in ENTEROS:
            if numero != int(numero):
                raise ErrorDeEntrada(f"el campo {campo} debe ser un número entero", [campo])
            numero = int(numero)
        paquete[campo] = numero

    for campo, opciones in OPCIONES.items():
        valor = str(datos[campo]).strip().lower()
        if valor not in opciones:
            raise ErrorDeEntrada(f"{campo} debe ser uno de: {', '.join(opciones)}", [campo])
        paquete[campo] = valor
    return paquete


def leer_entero_positivo(valor, campo):
    if isinstance(valor, bool):
        raise ErrorDeEntrada(f"{campo} debe ser un entero mayor o igual a 1", [campo])
    if isinstance(valor, str) and valor.strip().isdigit():
        valor = int(valor)
    if not isinstance(valor, int) or valor < 1:
        raise ErrorDeEntrada(f"{campo} debe ser un entero mayor o igual a 1", [campo])
    return valor


def recomendar(datos):
    """Calcula la recomendación completa sin registrar nada."""
    paquete = leer_caracteristicas(datos)
    sugerencia = obtener_recomendador().sugerir(paquete)
    plan = crear_tipo_envio(sugerencia.envio).planear(paquete)
    return paquete, {**sugerencia.a_dict(), "plan": plan}


def registrar_pedido(datos):
    """Recalcula la recomendación y guarda el pedido con folio.

    Un "resultado" enviado por el cliente se ignora: el servidor decide el envío.
    """
    paquete, resultado = recomendar(datos)

    producto = None
    if datos.get("producto_id") is not None:
        producto_id = leer_entero_positivo(datos["producto_id"], "producto_id")
        producto = ProductoRepositorio.obtener(producto_id)
        if producto is None:
            raise ErrorDeEntrada("el producto no existe", ["producto_id"])

    cantidad = leer_entero_positivo(datos.get("cantidad", paquete["cantidad_plantas"]), "cantidad")

    # No se descuenta stock: el pedido solo registra la operación.
    pedido = PedidoRepositorio.crear(producto, cantidad, paquete, resultado)
    return pedido_a_dict(pedido)


def buscar_pedido(folio):
    pedido = PedidoRepositorio.por_folio(folio)
    return pedido_a_dict(pedido) if pedido else None


def producto_a_dict(producto):
    return {
        "id": producto.id,
        "nombre": producto.nombre,
        "categoria": producto.categoria,
        "tipo_planta": producto.tipo_planta or None,
        "descripcion": producto.descripcion,
        "precio_mxn": float(producto.precio_mxn),
        "stock": producto.stock,
        "peso_kg": producto.peso_kg,
        "altura_cm": producto.altura_cm,
        "diametro_maceta_cm": producto.diametro_maceta_cm,
        "fragil": producto.fragil,
        "raiz_desnuda": producto.raiz_desnuda,
    }


def pedido_a_dict(pedido):
    return {
        "folio": pedido.folio,
        "creado_en": pedido.creado_en.isoformat(),
        "producto": {"id": pedido.producto.id, "nombre": pedido.producto.nombre} if pedido.producto else None,
        "cantidad": pedido.cantidad,
        "entradas": pedido.entradas,
        "resultado": pedido.resultado,
    }
