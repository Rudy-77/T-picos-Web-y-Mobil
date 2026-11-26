from django.urls import path, re_path

from . import views

urlpatterns = [
    path("productos/", views.productos, name="productos"),
    path("productos/<int:producto_id>/", views.producto_detalle, name="producto_detalle"),
    path("recomendar/", views.recomendar, name="recomendar"),
    path("pedidos/", views.pedidos, name="pedidos"),
    path("pedidos/<str:folio>/", views.pedido_por_folio, name="pedido_por_folio"),
    # Va al final: cualquier otra ruta de /api/ responde 404 en JSON, no en HTML.
    re_path(r"^(?P<ruta>.*)$", views.ruta_no_encontrada),
]
