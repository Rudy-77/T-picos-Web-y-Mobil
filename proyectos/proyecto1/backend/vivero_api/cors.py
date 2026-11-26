"""CORS mínimo, sin dependencias nuevas.

Flutter web corre en otro origen (por ejemplo http://localhost:54321) y el
navegador bloquea sus peticiones si el servidor no permite ese origen. Solo
aplica a /api/ y a orígenes locales o listados en CORS_ORIGENES_EXTRA.
"""

import re

from django.conf import settings
from django.http import HttpResponse

ORIGEN_LOCAL = re.compile(r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$")
PREFIJO_API = "/api/"


def origen_permitido(origen):
    return bool(ORIGEN_LOCAL.match(origen)) or origen in settings.CORS_ORIGENES_EXTRA


class CorsSimpleMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        origen = request.headers.get("Origin", "")
        aplica = request.path.startswith(PREFIJO_API) and origen_permitido(origen)

        # El navegador manda un OPTIONS ("preflight") antes de un POST con JSON.
        if aplica and request.method == "OPTIONS":
            respuesta = HttpResponse(status=204)
        else:
            respuesta = self.get_response(request)

        if aplica:
            respuesta["Access-Control-Allow-Origin"] = origen
            respuesta["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            respuesta["Access-Control-Allow-Headers"] = "Content-Type"
            respuesta["Vary"] = "Origin"
        return respuesta
