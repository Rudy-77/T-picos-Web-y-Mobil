"""Carga o actualiza el catálogo de prueba (se puede ejecutar varias veces sin duplicar)."""

from django.core.management.base import BaseCommand

from envios.models import Producto

CATALOGO = [
    ("Echeveria elegans", "planta", "suculenta", "Roseta azulada, ideal para interiores luminosos.", 65, 40, 0.3, 10, 8, False, False),
    ("Haworthia cebra", "planta", "suculenta", "Suculenta pequeña con franjas blancas; tolera poca luz.", 55, 35, 0.25, 9, 7, False, False),
    ("Aloe vera", "planta", "suculenta", "Planta medicinal de hojas carnosas.", 120, 25, 1.2, 35, 15, False, False),
    ("Monstera deliciosa", "planta", "interior_tropical", "Hojas grandes perforadas; necesita humedad.", 650, 8, 6.5, 110, 28, True, False),
    ("Ficus lyrata (1.5 m)", "planta", "interior_tropical", "Ficus hoja de violín de gran porte.", 1450, 3, 9.0, 150, 32, True, False),
    ("Pothos dorado", "planta", "interior_tropical", "Colgante de crecimiento rápido, muy resistente.", 180, 30, 1.0, 35, 14, False, False),
    ("Calathea orbifolia", "planta", "interior_tropical", "Hojas rayadas; sensible al frío y a la sequedad.", 420, 10, 1.8, 45, 18, True, False),
    ("Helecho de Boston", "planta", "helecho", "Frondas largas; requiere humedad constante.", 230, 18, 2.0, 50, 22, True, False),
    ("Lavanda", "planta", "exterior", "Aromática de exterior, soporta sol directo.", 140, 22, 1.1, 40, 15, False, False),
    ("Rosal miniatura a raíz desnuda", "planta", "exterior", "Rosal enviado sin maceta para plantar al recibir.", 190, 15, 0.6, 45, None, False, True),
    ("Limonero enano", "planta", "frutal", "Cítrico injertado que produce en maceta.", 780, 6, 9.5, 90, 30, False, False),
    ("Aguacate Hass injertado", "planta", "frutal", "Árbol joven a raíz desnuda, listo para plantar.", 520, 9, 3.0, 120, None, True, True),
    ("Charola de plántulas de jitomate", "planta", "hortaliza", "Charola de 12 plántulas listas para trasplante.", 90, 20, 1.5, 15, 5, True, False),
    ("Charola de lechuga romana", "planta", "hortaliza", "Charola de 12 plántulas de lechuga.", 75, 25, 1.2, 12, 5, True, False),
    ("Maceta de barro 25 cm", "maceta", "", "Barro cocido con orificio de drenaje.", 110, 40, 2.2, 22, 25, True, False),
    ("Maceta autorregable 30 cm", "maceta", "", "Plástico con depósito de agua.", 260, 15, 1.0, 28, 30, False, False),
    ("Sustrato para suculentas 5 kg", "sustrato", "", "Mezcla con tezontle y arena para buen drenaje.", 95, 50, 5.0, None, None, False, False),
    ("Tierra preparada 10 kg", "sustrato", "", "Mezcla con composta para plantas de interior.", 120, 45, 10.0, None, None, False, False),
    ("Fertilizante orgánico 1 kg", "fertilizante", "", "Humus de lombriz de liberación lenta.", 85, 60, 1.0, None, None, False, False),
    ("Fertilizante líquido para cítricos", "fertilizante", "", "Frasco de 500 ml con micronutrientes.", 140, 30, 0.6, None, None, False, False),
]


class Command(BaseCommand):
    help = "Carga o actualiza el catálogo de prueba del vivero."

    def handle(self, *args, **opciones):
        creados = 0
        for (nombre, categoria, tipo, descripcion, precio, stock, peso,
             altura, maceta, fragil, raiz) in CATALOGO:
            _, nuevo = Producto.objects.update_or_create(
                nombre=nombre,
                defaults={
                    "categoria": categoria, "tipo_planta": tipo, "descripcion": descripcion,
                    "precio_mxn": precio, "stock": stock, "peso_kg": peso, "altura_cm": altura,
                    "diametro_maceta_cm": maceta, "fragil": fragil, "raiz_desnuda": raiz,
                },
            )
            creados += nuevo
        self.stdout.write(self.style.SUCCESS(
            f"Catálogo listo: {len(CATALOGO)} productos ({creados} nuevos, {len(CATALOGO) - creados} actualizados)."
        ))
