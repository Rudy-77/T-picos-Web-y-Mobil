from django.db import models

TIPOS_PLANTA = [
    ("suculenta", "Suculenta"),
    ("interior_tropical", "Interior tropical"),
    ("exterior", "Exterior"),
    ("frutal", "Frutal"),
    ("hortaliza", "Hortaliza"),
    ("helecho", "Helecho"),
]

CATEGORIAS = [
    ("planta", "Planta"),
    ("maceta", "Maceta"),
    ("sustrato", "Sustrato"),
    ("fertilizante", "Fertilizante"),
]


class Producto(models.Model):
    nombre = models.CharField(max_length=100, unique=True)
    categoria = models.CharField(max_length=20, choices=CATEGORIAS)
    tipo_planta = models.CharField(max_length=20, choices=TIPOS_PLANTA, blank=True)  # vacío si no es planta
    descripcion = models.TextField(blank=True)
    precio_mxn = models.DecimalField(max_digits=10, decimal_places=2)
    stock = models.PositiveIntegerField(default=0)
    peso_kg = models.FloatField()
    altura_cm = models.FloatField(null=True, blank=True)
    diametro_maceta_cm = models.FloatField(null=True, blank=True)
    fragil = models.BooleanField(default=False)
    raiz_desnuda = models.BooleanField(default=False)

    class Meta:
        ordering = ["categoria", "nombre"]

    def __str__(self):
        return self.nombre


class Pedido(models.Model):
    """Pedido con la recomendación que calculó el servidor.

    Se guarda la respuesta completa para poder explicarla después aunque el modelo cambie.
    """

    folio = models.CharField(max_length=20, unique=True)
    producto = models.ForeignKey(Producto, null=True, blank=True, on_delete=models.SET_NULL,
                                 related_name="pedidos")
    cantidad = models.PositiveIntegerField(default=1)
    entradas = models.JSONField()
    resultado = models.JSONField()
    envio = models.CharField(max_length=20)
    creado_en = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-creado_en"]

    def __str__(self):
        return self.folio
