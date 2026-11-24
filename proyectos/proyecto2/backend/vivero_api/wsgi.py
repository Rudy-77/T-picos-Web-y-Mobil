"""Punto de entrada WSGI del servidor."""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'vivero_api.settings')

application = get_wsgi_application()
