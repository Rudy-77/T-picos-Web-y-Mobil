"""Punto de entrada ASGI del servidor."""

import os

from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'vivero_api.settings')

application = get_asgi_application()
