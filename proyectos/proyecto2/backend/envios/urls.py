from django.urls import path, re_path

from . import views

urlpatterns = [
    path("productos/", views.productos, name="productos"),
    path("productos/<int:producto_id>/", views.producto_detalle, name="producto_detalle"),
    path("recomendar/", views.recomendar, name="recomendar"),
    path("pedidos/", views.pedidos, name="pedidos"),
    path("pedidos/<str:folio>/", views.pedido_por_folio, name="pedido_por_folio"),
    path("asistente/", views.asistente_chat, name="asistente"),
    # La dejo al final para que cualquier otra ruta de /api/ responda 404 en JSON.
    re_path(r"^(?P<ruta>.*)$", views.ruta_no_encontrada),
]
