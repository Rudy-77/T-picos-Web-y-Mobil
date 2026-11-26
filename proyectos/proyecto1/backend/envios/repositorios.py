"""Patrón Repository: el único lugar que consulta y guarda en la base de datos."""

from django.db import IntegrityError, transaction
from django.db.models import Q
from django.utils import timezone

from .models import Pedido, Producto

INTENTOS_FOLIO = 5


class ProductoRepositorio:
    @staticmethod
    def listar(texto="", categoria=""):
        productos = Producto.objects.all()
        if texto:
            productos = productos.filter(
                Q(nombre__icontains=texto) | Q(descripcion__icontains=texto)
                | Q(tipo_planta__icontains=texto) | Q(categoria__icontains=texto)
            )
        if categoria:
            productos = productos.filter(categoria=categoria)
        return productos

    @staticmethod
    def obtener(producto_id):
        return Producto.objects.filter(pk=producto_id).first()


class PedidoRepositorio:
    @staticmethod
    def por_folio(folio):
        return Pedido.objects.select_related("producto").filter(folio=folio).first()

    @staticmethod
    def siguiente_folio(fecha=None):
        """Folio consecutivo del día: VIV-AAAAMMDD-0001, VIV-AAAAMMDD-0002, ..."""
        fecha = fecha or timezone.localdate()
        prefijo = f"VIV-{fecha:%Y%m%d}-"
        ultimo = (Pedido.objects.filter(folio__startswith=prefijo)
                  .order_by("-folio").values_list("folio", flat=True).first())
        numero = int(ultimo.rsplit("-", 1)[1]) + 1 if ultimo else 1
        return f"{prefijo}{numero:04d}"

    @classmethod
    def crear(cls, producto, cantidad, entradas, resultado):
        # Dos pedidos simultáneos pueden calcular el mismo folio; como es único,
        # si choca se recalcula y se reintenta.
        for _ in range(INTENTOS_FOLIO):
            try:
                with transaction.atomic():
                    return Pedido.objects.create(
                        folio=cls.siguiente_folio(), producto=producto, cantidad=cantidad,
                        entradas=entradas, resultado=resultado, envio=resultado["envio"],
                    )
            except IntegrityError:
                continue
        raise RuntimeError("no se pudo asignar un folio único")
