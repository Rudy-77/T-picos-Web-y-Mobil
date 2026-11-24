"""Front Controller: toda petición entra por aquí y se reparte a su vista."""

from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include("envios.urls")),
]
