from django.contrib import admin

from .models import Pedido, Producto


@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    list_display = ["nombre", "categoria", "tipo_planta", "precio_mxn", "stock"]
    list_filter = ["categoria", "tipo_planta"]
    search_fields = ["nombre", "descripcion"]


@admin.register(Pedido)
class PedidoAdmin(admin.ModelAdmin):
    list_display = ["folio", "producto", "cantidad", "envio", "creado_en"]
    list_filter = ["envio"]
    search_fields = ["folio"]
