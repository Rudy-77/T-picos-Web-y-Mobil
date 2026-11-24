"""Vistas de la API: solo traducen HTTP a diccionarios; la lógica está en servicios.py."""

import json
from functools import wraps

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from . import servicios
from .asistente import asistente
from .models import CATEGORIAS
from .repositorios import ProductoRepositorio


MAX_MENSAJE = 500


def responder(datos, status=200):
    return JsonResponse(datos, status=status, json_dumps_params={"ensure_ascii": False})


def solo_metodo(metodo):
    """Como require_GET/require_POST, pero el error 405 también sale en JSON."""
    def decorador(vista):
        @wraps(vista)
        def envoltura(request, *args, **kwargs):
            if request.method != metodo:
                respuesta = responder({"error": f"método no permitido; usa {metodo}"}, status=405)
                respuesta["Allow"] = metodo
                return respuesta
            return vista(request, *args, **kwargs)
        return envoltura
    return decorador


def leer_json(request):
    try:
        return json.loads(request.body)
    except (json.JSONDecodeError, UnicodeDecodeError):
        raise servicios.ErrorDeEntrada("el cuerpo debe ser JSON válido")


@solo_metodo("GET")
def productos(request):
    texto = request.GET.get("q", "").strip()
    categoria = request.GET.get("categoria", "").strip()
    if categoria and categoria not in dict(CATEGORIAS):
        return responder({"error": f"categoria debe ser una de: {', '.join(dict(CATEGORIAS))}"}, status=400)
    encontrados = [servicios.producto_a_dict(p) for p in ProductoRepositorio.listar(texto, categoria)]
    return responder({"total": len(encontrados), "productos": encontrados})


@solo_metodo("GET")
def producto_detalle(request, producto_id):
    producto = ProductoRepositorio.obtener(producto_id)
    if producto is None:
        return responder({"error": "producto no encontrado"}, status=404)
    return responder(servicios.producto_a_dict(producto))


@csrf_exempt
@solo_metodo("POST")
def recomendar(request):
    try:
        entradas, resultado = servicios.recomendar(leer_json(request))
    except servicios.ErrorDeEntrada as error:
        return responder(error.a_dict(), status=400)
    return responder({"entradas": entradas, "resultado": resultado})


@csrf_exempt
@solo_metodo("POST")
def pedidos(request):
    try:
        pedido = servicios.registrar_pedido(leer_json(request))
    except servicios.ErrorDeEntrada as error:
        return responder(error.a_dict(), status=400)
    return responder(pedido, status=201)


@solo_metodo("GET")
def pedido_por_folio(request, folio):
    pedido = servicios.buscar_pedido(folio.strip().upper())
    if pedido is None:
        return responder({"error": f"no existe un pedido con folio {folio}"}, status=404)
    return responder(pedido)


def leer_mensaje(datos):
    if not isinstance(datos, dict):
        raise servicios.ErrorDeEntrada("el cuerpo debe ser un objeto JSON")
    mensaje = datos.get("mensaje", datos.get("texto"))
    if not isinstance(mensaje, str) or not mensaje.strip():
        raise servicios.ErrorDeEntrada("falta el mensaje", ["mensaje"])
    if len(mensaje) > MAX_MENSAJE:
        raise servicios.ErrorDeEntrada(f"el mensaje no puede pasar de {MAX_MENSAJE} caracteres", ["mensaje"])
    contexto = datos.get("contexto")
    return mensaje.strip(), contexto if isinstance(contexto, dict) else {}


def listar_para_asistente(texto, categoria=""):
    return [servicios.producto_a_dict(p) for p in ProductoRepositorio.listar(texto, categoria)]


@csrf_exempt
@solo_metodo("POST")
def asistente_chat(request):
    try:
        mensaje, contexto = leer_mensaje(leer_json(request))
    except servicios.ErrorDeEntrada as error:
        return responder(error.a_dict(), status=400)
    return responder(asistente.responder(
        mensaje, contexto,
        buscar_pedido=servicios.buscar_pedido,
        listar_productos=listar_para_asistente,
    ))


def ruta_no_encontrada(request, ruta=""):
    return responder({"error": f"no existe la ruta {request.path}"}, status=404)
