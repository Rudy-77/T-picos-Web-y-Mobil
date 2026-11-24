"""Pruebas del asistente: folios, clasificador, respuestas por intención y endpoint."""

import io
import json
from unittest import TestCase as TestCaseSimple

from django.core.management import call_command
from django.test import TestCase

from envios.asistente import asistente
from envios.asistente.clasificador import ClasificadorIntenciones, Intencion, obtener_clasificador
from envios.asistente.texto import extraer_folio, normalizar
from envios.tests.test_api import CARACTERISTICAS, CASO

ENVIOS = ["estandar", "protegido", "humedad", "termico", "estándar", "térmico"]


class ClasificadorFalso(ClasificadorIntenciones):
    def __init__(self, nombre, confianza=0.9):
        self._intencion = Intencion(nombre, confianza)

    def clasificar(self, texto):
        return self._intencion


def pedido_falso(corregido=True):
    return {
        "folio": "VIV-20261123-0001",
        "creado_en": "2026-11-23T10:00:00-06:00",
        "producto": {"id": 1, "nombre": "Helecho de Boston"},
        "cantidad": 2,
        "entradas": {"peso_kg": 2},
        "resultado": {
            "envio": "protegido", "confianza": 0.62, "preferido_por_modelo": "humedad",
            "corregido_por_reglas": corregido, "sin_opcion_valida": False, "motivo": "árbol de decisión, confianza 62%",
            "descartados": [{"envio": "humedad", "motivo": "la humedad pudre las suculentas"}] if corregido else [],
            "plan": {"empaque": "caja reforzada", "dias": 2, "costo_estimado_mxn": 210.5,
                     "riego_sugerido": "Regar 24 h antes de empacar."},
        },
    }


def producto_falso(id_, nombre):
    return {"id": id_, "nombre": nombre, "categoria": "planta"}


class PruebasFolio(TestCaseSimple):
    def test_formatos_validos(self):
        casos = {
            "mi folio es VIV-20261123-0001": "VIV-20261123-0001",
            "viv-20261123-0001": "VIV-20261123-0001",
            "viv 20261123 0001": "VIV-20261123-0001",
            "VIV202611230001": "VIV-20261123-0001",
            "viv-20261123-1": "VIV-20261123-0001",
            "folio VIV-20261123-0012, gracias": "VIV-20261123-0012",
            "VIV_20261123_0003": "VIV-20261123-0003",
        }
        for texto, esperado in casos.items():
            self.assertEqual(extraer_folio(texto), esperado, texto)

    def test_casos_sin_folio(self):
        for texto in ["", None, "hola", "viv-2026-0001", "VIV-20261123", "aviv-20261123-0001",
                      "VIV-20261123-00012345", "mi pedido"]:
            self.assertIsNone(extraer_folio(texto), texto)

    def test_con_dos_folios_toma_el_primero(self):
        self.assertEqual(extraer_folio("VIV-20261123-0001 y VIV-20261123-0002"), "VIV-20261123-0001")

    def test_normalizar_cambia_el_folio_por_un_token(self):
        self.assertNotIn("2026", normalizar("estado de VIV-20261123-0001"))
        self.assertEqual(normalizar("hola"), "hola")


class PruebasClasificador(TestCaseSimple):
    def test_frases_nuevas(self):
        casos = {
            "hola, muy buenas": "saludo",
            "muchas gracias, hasta luego": "despedida_gracias",
            "quiero ver el estado de mi pedido VIV-20261123-0001": "rastreo_folio",
            "¿por qué me salió protegido?": "explicar_recomendacion",
            "¿tienen helechos?": "buscar_producto",
            "¿qué envío me conviene para mandar un cactus?": "recomendar_envio",
            "¿qué diferencia hay entre térmico y estándar?": "info_envios",
        }
        clasificador = obtener_clasificador()
        for texto, esperado in casos.items():
            intencion = clasificador.clasificar(texto)
            self.assertEqual(intencion.nombre, esperado, texto)
            self.assertGreaterEqual(intencion.confianza, asistente.UMBRAL_CONFIANZA, texto)

    def test_se_carga_una_sola_vez(self):
        self.assertIs(obtener_clasificador(), obtener_clasificador())


class PruebasResponder(TestCaseSimple):
    def responder(self, intencion, mensaje="", contexto=None, pedido=None, productos=(), confianza=0.9):
        return asistente.responder(
            mensaje, contexto or {},
            buscar_pedido=lambda folio: pedido,
            listar_productos=lambda texto: [p for p in productos if texto.lower() in p["nombre"].lower()],
            clasificador=ClasificadorFalso(intencion, confianza),
        )

    def test_saludo_y_despedida(self):
        self.assertEqual(self.responder("saludo")["intencion"], "saludo")
        self.assertEqual(self.responder("despedida_gracias")["intencion"], "despedida_gracias")

    def test_rastreo_con_folio_existente(self):
        datos = self.responder("rastreo_folio", "VIV-20261123-0001", pedido=pedido_falso())
        self.assertEqual(datos["folio"], "VIV-20261123-0001")
        self.assertEqual(datos["pedido"]["envio"], "protegido")
        self.assertNotIn("entradas", datos["pedido"])
        self.assertIn("no tiene seguimiento de paquetería", datos["respuesta"])

    def test_rastreo_con_folio_inexistente(self):
        datos = self.responder("rastreo_folio", "VIV-20261123-0099", pedido=None)
        self.assertIn("No encontré", datos["respuesta"])
        self.assertNotIn("pedido", datos)

    def test_rastreo_sin_folio_lo_pide(self):
        datos = self.responder("rastreo_folio", "¿cómo va mi pedido?")
        self.assertIn("necesito el folio", datos["respuesta"])

    def test_usa_el_ultimo_folio_del_contexto(self):
        datos = self.responder("explicar_recomendacion", "¿por qué me salió así?",
                               contexto={"ultimo_folio": "viv-20261123-0001"}, pedido=pedido_falso())
        self.assertEqual(datos["folio"], "VIV-20261123-0001")
        self.assertIn("Usé tu último folio", datos["respuesta"])

    def test_el_folio_del_mensaje_gana_al_contexto(self):
        folios = []
        asistente.responder(
            "VIV-20261123-0002", {"ultimo_folio": "VIV-20261123-0001"},
            buscar_pedido=lambda folio: folios.append(folio),
            listar_productos=lambda texto: [],
            clasificador=ClasificadorFalso("rastreo_folio"),
        )
        self.assertEqual(folios, ["VIV-20261123-0002"])

    def test_explicacion_usa_lo_guardado(self):
        datos = self.responder("explicar_recomendacion", "VIV-20261123-0001", pedido=pedido_falso())
        self.assertIn("prefería humedad", datos["respuesta"])
        self.assertIn("las reglas del vivero lo descartaron", datos["respuesta"])
        self.assertIn("la humedad pudre las suculentas", datos["respuesta"])
        self.assertIn("registrado el 2026-11-23", self.responder(
            "rastreo_folio", "VIV-20261123-0001", pedido=pedido_falso())["respuesta"])

    def test_explicacion_sin_correccion(self):
        datos = self.responder("explicar_recomendacion", "VIV-20261123-0001", pedido=pedido_falso(corregido=False))
        self.assertIn("ninguna regla lo impedía", datos["respuesta"])

    def test_explicacion_sin_folio_lo_pide(self):
        datos = self.responder("explicar_recomendacion", "¿por qué me salió protegido?")
        self.assertIn("necesito el folio", datos["respuesta"])

    def test_buscar_producto_ordena_por_coincidencias(self):
        productos = [producto_falso(1, "Helecho de Boston"), producto_falso(2, "Lavanda")]
        datos = self.responder("buscar_producto", "¿tienen helechos?", productos=productos)
        self.assertEqual([p["id"] for p in datos["productos"]], [1])

    def test_buscar_producto_sin_resultados(self):
        datos = self.responder("buscar_producto", "¿tienen orquídeas?", productos=[producto_falso(1, "Lavanda")])
        self.assertNotIn("productos", datos)
        self.assertIn("No encontré", datos["respuesta"])

    def test_buscar_producto_limita_a_cinco(self):
        productos = [producto_falso(i, f"Planta {i}") for i in range(1, 10)]
        datos = asistente.responder(
            "muéstrame el catálogo", {}, buscar_pedido=lambda f: None,
            listar_productos=lambda texto: productos,
            clasificador=ClasificadorFalso("buscar_producto"),
        )
        self.assertEqual(len(datos["productos"]), 5)

    def test_recomendar_envio_no_elige_un_envio(self):
        datos = self.responder("recomendar_envio", "¿cómo mando un cactus?")
        self.assertEqual(datos["accion"]["tipo"], "abrir_formulario_envio")
        self.assertEqual(datos["accion"]["endpoint"], "/api/recomendar/")
        for llave in ("envio", "pedido", "productos"):
            self.assertNotIn(llave, datos)
        texto = datos["respuesta"].lower()
        for envio in ENVIOS:
            self.assertNotIn(envio, texto)

    def test_info_envios_compara_los_nombrados(self):
        datos = self.responder("info_envios", "¿qué diferencia hay entre protegido y humedad?")
        self.assertIn("Protegido:", datos["respuesta"])
        self.assertIn("Humedad:", datos["respuesta"])
        self.assertNotIn("Térmico:", datos["respuesta"])

    def test_info_envios_sin_nombres_lista_todos(self):
        datos = self.responder("info_envios", "¿qué tipos de envío tienen?")
        for nombre in ("Estándar:", "Protegido:", "Humedad:", "Térmico:"):
            self.assertIn(nombre, datos["respuesta"])

    def test_confianza_baja_se_responde_como_no_se(self):
        datos = self.responder("rastreo_folio", "VIV-20261123-0001", pedido=pedido_falso(), confianza=0.2)
        self.assertEqual(datos["intencion"], "no_se")
        self.assertNotIn("pedido", datos)


class PruebasEndpoint(TestCase):
    @classmethod
    def setUpTestData(cls):
        call_command("cargar_datos_prueba", stdout=io.StringIO())

    def preguntar(self, mensaje, **extra):
        cuerpo = {"mensaje": mensaje, **extra}
        return self.client.post("/api/asistente/", data=json.dumps(cuerpo), content_type="application/json")

    def crear_pedido(self, entrada):
        return self.client.post("/api/pedidos/", data=json.dumps(entrada), content_type="application/json").json()

    def test_saludo(self):
        respuesta = self.preguntar("hola, buenas tardes")
        self.assertEqual(respuesta.status_code, 200)
        datos = respuesta.json()
        self.assertEqual(datos["intencion"], "saludo")
        self.assertIn("respuesta", datos)
        self.assertIn("confianza", datos)

    def test_acepta_texto_en_vez_de_mensaje(self):
        respuesta = self.client.post("/api/asistente/", data=json.dumps({"texto": "hola"}),
                                     content_type="application/json")
        self.assertEqual(respuesta.json()["intencion"], "saludo")

    def test_mensaje_invalido(self):
        for cuerpo in [{}, {"mensaje": ""}, {"mensaje": "   "}, {"mensaje": 5}, {"mensaje": "a" * 501}, [1, 2]]:
            respuesta = self.client.post("/api/asistente/", data=json.dumps(cuerpo),
                                         content_type="application/json")
            self.assertEqual(respuesta.status_code, 400, cuerpo)
            self.assertIn("error", respuesta.json())

    def test_json_invalido(self):
        respuesta = self.client.post("/api/asistente/", data="no es json", content_type="application/json")
        self.assertEqual(respuesta.status_code, 400)

    def test_metodo_no_permitido(self):
        respuesta = self.client.get("/api/asistente/")
        self.assertEqual(respuesta.status_code, 405)
        self.assertIn("error", respuesta.json())

    def test_consulta_con_folio_existente(self):
        folio = self.crear_pedido(CARACTERISTICAS)["folio"]
        datos = self.preguntar(f"¿cómo va mi pedido {folio.lower()}?").json()
        self.assertEqual(datos["intencion"], "rastreo_folio")
        self.assertEqual(datos["folio"], folio)
        self.assertIn("plan", datos["pedido"])

    def test_consulta_con_folio_inexistente(self):
        datos = self.preguntar("estado del pedido VIV-20200101-0001").json()
        self.assertEqual(datos["intencion"], "rastreo_folio")
        self.assertIn("No encontré", datos["respuesta"])

    def test_explicacion_de_un_pedido_corregido(self):
        folio = self.crear_pedido(CASO["entrada"])["folio"]
        datos = self.preguntar(f"¿por qué me salió ese envío en el pedido {folio}?").json()
        self.assertEqual(datos["intencion"], "explicar_recomendacion")
        self.assertIn("las reglas del vivero lo descartaron", datos["respuesta"])
        self.assertIn(CASO["resultado_esperado"]["envio"].replace("termico", "térmico"), datos["respuesta"])

    def test_explicacion_con_el_ultimo_folio(self):
        folio = self.crear_pedido(CARACTERISTICAS)["folio"]
        datos = self.preguntar("¿por qué me salió ese resultado?", contexto={"ultimo_folio": folio}).json()
        self.assertEqual(datos["folio"], folio)

    def test_busqueda_de_productos(self):
        datos = self.preguntar("¿tienen helechos?").json()
        self.assertEqual(datos["intencion"], "buscar_producto")
        self.assertEqual(datos["productos"][0]["nombre"], "Helecho de Boston")

    def test_recomendar_envio_remite_al_recomendador(self):
        datos = self.preguntar("¿qué envío me recomiendas para mandar un helecho?").json()
        self.assertEqual(datos["intencion"], "recomendar_envio")
        self.assertIn("accion", datos)
        self.assertNotIn("envio", datos)

    def test_fuera_de_dominio(self):
        datos = self.preguntar("¿cuál es la capital de Francia?").json()
        self.assertEqual(datos["intencion"], "no_se")
        self.assertIn("rastrear", datos["respuesta"])

    def test_no_registra_pedidos(self):
        from envios.models import Pedido
        self.preguntar("quiero hacer un pedido")
        self.assertEqual(Pedido.objects.count(), 0)
