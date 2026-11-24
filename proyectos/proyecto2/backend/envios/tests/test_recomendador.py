"""Pruebas de reglas, tipos de envío y recomendador (no usan la base de datos)."""

import json
import unittest
from pathlib import Path

from envios.recomendador import RecomendadorIA, obtener_recomendador
from envios.reglas import ENVIOS, es_posible, motivo_descarte
from envios.tipos_envio import TIPOS_ENVIO, crear_tipo_envio

RUTA_CASO = Path(__file__).resolve().parents[3] / "ml" / "ejemplos" / "caso_correccion.json"

PEDIDO_BASE = {
    "distancia_km": 25.0, "peso_kg": 2.0, "altura_cm": 40.0, "diametro_maceta_cm": 15.0,
    "cantidad_plantas": 2, "valor_declarado_mxn": 400.0, "temperatura_destino_c": 20.0,
    "dias_en_transito": 1, "fragil": 0, "raiz_desnuda": 0,
    "tipo_planta": "exterior", "epoca": "primavera", "prioridad": "normal", "zona_destino": "urbana",
}


def pedido(**cambios):
    return {**PEDIDO_BASE, **cambios}


class PruebasReglas(unittest.TestCase):
    def test_pedido_base_admite_todos_los_envios(self):
        for envio in ENVIOS:
            self.assertTrue(es_posible(envio, PEDIDO_BASE), envio)

    def test_estandar(self):
        self.assertFalse(es_posible("estandar", pedido(raiz_desnuda=1)))
        self.assertFalse(es_posible("estandar", pedido(temperatura_destino_c=4.9)))
        self.assertFalse(es_posible("estandar", pedido(temperatura_destino_c=35.1)))
        self.assertFalse(es_posible("estandar", pedido(dias_en_transito=4)))
        self.assertTrue(es_posible("estandar", pedido(dias_en_transito=3)))

    def test_protegido(self):
        self.assertTrue(es_posible("protegido", pedido(raiz_desnuda=1, dias_en_transito=2)))
        self.assertFalse(es_posible("protegido", pedido(raiz_desnuda=1, dias_en_transito=3)))
        self.assertFalse(es_posible("protegido", pedido(temperatura_destino_c=-1)))
        self.assertFalse(es_posible("protegido", pedido(temperatura_destino_c=39)))

    def test_humedad(self):
        self.assertFalse(es_posible("humedad", pedido(altura_cm=121)))
        self.assertFalse(es_posible("humedad", pedido(temperatura_destino_c=2.9)))
        self.assertFalse(es_posible("humedad", pedido(tipo_planta="suculenta")))

    def test_termico(self):
        self.assertFalse(es_posible("termico", pedido(dias_en_transito=6)))
        self.assertFalse(es_posible("termico", pedido(valor_declarado_mxn=149.99)))
        self.assertTrue(es_posible("termico", pedido(dias_en_transito=5, valor_declarado_mxn=150)))

    def test_motivo_explica_el_descarte(self):
        self.assertIn("120 cm", motivo_descarte("humedad", pedido(altura_cm=150)))
        self.assertIsNone(motivo_descarte("humedad", PEDIDO_BASE))


class PruebasTiposEnvio(unittest.TestCase):
    def test_cada_estrategia_devuelve_el_plan_completo(self):
        llaves = {"envio", "empaque", "dias", "costo_estimado_mxn", "indicacion", "riego_sugerido"}
        for nombre in TIPOS_ENVIO:
            plan = crear_tipo_envio(nombre).planear(PEDIDO_BASE)
            self.assertEqual(set(plan), llaves)
            self.assertEqual(plan["envio"], nombre)
            self.assertGreater(plan["costo_estimado_mxn"], 0)

    def test_express_cuesta_mas(self):
        normal = crear_tipo_envio("estandar").planear(PEDIDO_BASE)
        express = crear_tipo_envio("estandar").planear(pedido(prioridad="express"))
        self.assertGreater(express["costo_estimado_mxn"], normal["costo_estimado_mxn"])

    def test_riego_de_suculenta_no_pide_regar_antes(self):
        plan = crear_tipo_envio("estandar").planear(pedido(tipo_planta="suculenta"))
        self.assertIn("No regar antes", plan["riego_sugerido"])


class PruebasRecomendador(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.recomendador = obtener_recomendador()

    def test_es_un_recomendador_ia(self):
        self.assertIsInstance(self.recomendador, RecomendadorIA)

    def test_sugerencia_trae_todo_lo_que_pide_la_app(self):
        s = self.recomendador.sugerir(PEDIDO_BASE)
        self.assertIn(s.envio, ENVIOS)
        self.assertEqual(len(s.ranking), len(ENVIOS))
        self.assertAlmostEqual(sum(o["probabilidad"] for o in s.ranking), 1.0, places=2)
        self.assertTrue(0 <= s.confianza <= 1)
        probabilidades = [o["probabilidad"] for o in s.ranking]
        self.assertEqual(probabilidades, sorted(probabilidades, reverse=True))

    def test_el_envio_elegido_siempre_cumple_las_reglas(self):
        for cambios in [{}, {"raiz_desnuda": 1}, {"temperatura_destino_c": 1},
                        {"altura_cm": 160, "tipo_planta": "frutal"}, {"dias_en_transito": 5}]:
            p = pedido(**cambios)
            s = self.recomendador.sugerir(p)
            if not s.sin_opcion_valida:
                self.assertTrue(es_posible(s.envio, p), cambios)

    def test_caso_reproducible_de_correccion(self):
        caso = json.loads(RUTA_CASO.read_text(encoding="utf-8"))
        esperado = caso["resultado_esperado"]
        s = self.recomendador.sugerir(caso["entrada"])

        self.assertTrue(s.corregido_por_reglas)
        self.assertEqual(s.preferido_por_modelo, "humedad")
        self.assertNotEqual(s.envio, s.preferido_por_modelo)
        self.assertFalse(es_posible("humedad", caso["entrada"]))
        self.assertEqual(s.envio, esperado["envio"])
        self.assertEqual(s.ranking, esperado["ranking"])

    def test_sin_opcion_valida_usa_respaldo_termico(self):
        # Armo un caso con raíz desnuda, helada, 6 días y valor bajo: ninguna regla lo permite.
        p = pedido(raiz_desnuda=1, temperatura_destino_c=-3, dias_en_transito=6,
                   valor_declarado_mxn=100, epoca="invierno", zona_destino="rural", distancia_km=850)
        s = self.recomendador.sugerir(p)
        self.assertTrue(s.sin_opcion_valida)
        self.assertEqual(s.envio, "termico")
        self.assertEqual(s.confianza, 0.0)
        self.assertTrue(s.corregido_por_reglas)
        self.assertEqual(len(s.descartados), len(ENVIOS))
        self.assertIn("respaldo", s.motivo)


if __name__ == "__main__":
    unittest.main()
