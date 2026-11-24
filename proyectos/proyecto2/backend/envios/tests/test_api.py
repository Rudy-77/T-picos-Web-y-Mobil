"""Pruebas de los endpoints con el cliente de pruebas de Django."""

import io
import json
from datetime import date
from pathlib import Path

from django.core.management import call_command
from django.test import TestCase

from envios.models import Pedido, Producto
from envios.repositorios import PedidoRepositorio

RUTA_CASO = Path(__file__).resolve().parents[3] / "ml" / "ejemplos" / "caso_correccion.json"
CASO = json.loads(RUTA_CASO.read_text(encoding="utf-8"))

CARACTERISTICAS = {
    "distancia_km": 25, "peso_kg": 2, "altura_cm": 40, "diametro_maceta_cm": 15,
    "cantidad_plantas": 2, "valor_declarado_mxn": 400, "temperatura_destino_c": 20,
    "dias_en_transito": 1, "fragil": False, "raiz_desnuda": False,
    "tipo_planta": "exterior", "epoca": "primavera", "prioridad": "normal", "zona_destino": "urbana",
}


class PruebasApi(TestCase):
    @classmethod
    def setUpTestData(cls):
        call_command("cargar_datos_prueba", stdout=io.StringIO())

    def post(self, url, datos):
        return self.client.post(url, data=json.dumps(datos), content_type="application/json")

    def test_listado_de_productos(self):
        respuesta = self.client.get("/api/productos/")
        self.assertEqual(respuesta.status_code, 200)
        datos = respuesta.json()
        self.assertEqual(datos["total"], Producto.objects.count())
        self.assertIn("precio_mxn", datos["productos"][0])

    def test_busqueda_y_filtro(self):
        datos = self.client.get("/api/productos/", {"q": "suculenta"}).json()
        self.assertGreater(datos["total"], 0)
        self.assertTrue(all("suculenta" in (p["tipo_planta"] or "") + p["nombre"].lower() + p["descripcion"].lower()
                            for p in datos["productos"]))
        macetas = self.client.get("/api/productos/", {"categoria": "maceta"}).json()
        self.assertTrue(all(p["categoria"] == "maceta" for p in macetas["productos"]))
        self.assertEqual(self.client.get("/api/productos/", {"categoria": "zapato"}).status_code, 400)

    def test_detalle_de_producto(self):
        producto = Producto.objects.get(nombre="Monstera deliciosa")
        datos = self.client.get(f"/api/productos/{producto.id}/").json()
        self.assertEqual(datos["tipo_planta"], "interior_tropical")
        self.assertEqual(self.client.get("/api/productos/99999/").status_code, 404)

    def test_recomendar_devuelve_la_respuesta_completa(self):
        respuesta = self.post("/api/recomendar/", CARACTERISTICAS)
        self.assertEqual(respuesta.status_code, 200)
        resultado = respuesta.json()["resultado"]
        for llave in ["envio", "confianza", "preferido_por_modelo", "corregido_por_reglas",
                      "ranking", "descartados", "motivo", "plan", "sin_opcion_valida"]:
            self.assertIn(llave, resultado)
        self.assertEqual(Pedido.objects.count(), 0)

    def test_recomendar_reproduce_el_caso_de_correccion(self):
        resultado = self.post("/api/recomendar/", CASO["entrada"]).json()["resultado"]
        self.assertTrue(resultado["corregido_por_reglas"])
        self.assertEqual(resultado["preferido_por_modelo"], "humedad")
        self.assertEqual(resultado["envio"], CASO["resultado_esperado"]["envio"])

    def test_recomendar_valida_entradas(self):
        self.assertEqual(self.client.post("/api/recomendar/", data="no es json",
                                          content_type="application/json").status_code, 400)
        incompleto = {k: v for k, v in CARACTERISTICAS.items() if k != "epoca"}
        respuesta = self.post("/api/recomendar/", incompleto)
        self.assertEqual(respuesta.status_code, 400)
        self.assertEqual(respuesta.json()["campos"], ["epoca"])
        self.assertEqual(self.post("/api/recomendar/", {**CARACTERISTICAS, "peso_kg": "mucho"}).status_code, 400)
        self.assertEqual(self.post("/api/recomendar/", {**CARACTERISTICAS, "tipo_planta": "cactus"}).status_code, 400)
        self.assertEqual(self.post("/api/recomendar/", {**CARACTERISTICAS, "dias_en_transito": 0}).status_code, 400)

    def test_registrar_pedido_y_consultarlo_por_folio(self):
        producto = Producto.objects.get(nombre="Lavanda")
        respuesta = self.post("/api/pedidos/", {**CARACTERISTICAS, "producto_id": producto.id, "cantidad": 3})
        self.assertEqual(respuesta.status_code, 201)
        pedido = respuesta.json()
        self.assertRegex(pedido["folio"], r"^VIV-\d{8}-0001$")
        self.assertEqual(pedido["producto"]["nombre"], "Lavanda")
        self.assertEqual(pedido["cantidad"], 3)

        consulta = self.client.get(f"/api/pedidos/{pedido['folio']}/")
        self.assertEqual(consulta.status_code, 200)
        self.assertEqual(consulta.json()["resultado"], pedido["resultado"])
        self.assertEqual(Producto.objects.get(pk=producto.id).stock, producto.stock)

    def test_el_servidor_recalcula_e_ignora_el_resultado_del_cliente(self):
        trampa = {**CASO["entrada"], "resultado": {"envio": "estandar"}, "envio": "estandar"}
        pedido = self.post("/api/pedidos/", trampa).json()
        self.assertEqual(pedido["resultado"]["envio"], CASO["resultado_esperado"]["envio"])
        self.assertTrue(pedido["resultado"]["corregido_por_reglas"])
        self.assertNotIn("resultado", pedido["entradas"])

    def test_folios_consecutivos(self):
        primero = self.post("/api/pedidos/", CARACTERISTICAS).json()["folio"]
        segundo = self.post("/api/pedidos/", CARACTERISTICAS).json()["folio"]
        self.assertTrue(primero.endswith("-0001"))
        self.assertTrue(segundo.endswith("-0002"))
        self.assertEqual(PedidoRepositorio.siguiente_folio(date(2026, 1, 5)), "VIV-20260105-0001")

    def test_pedido_con_errores(self):
        self.assertEqual(self.post("/api/pedidos/", {**CARACTERISTICAS, "producto_id": 99999}).status_code, 400)
        self.assertEqual(self.post("/api/pedidos/", {**CARACTERISTICAS, "cantidad": 0}).status_code, 400)
        self.assertEqual(Pedido.objects.count(), 0)
        self.assertEqual(self.client.get("/api/pedidos/VIV-20000101-0001/").status_code, 404)

    def test_rangos_y_tipos_invalidos(self):
        for cambio in [{"peso_kg": 0}, {"distancia_km": 1e9}, {"altura_cm": -5},
                       {"dias_en_transito": 2.5}, {"temperatura_destino_c": -40}]:
            respuesta = self.post("/api/recomendar/", {**CARACTERISTICAS, **cambio})
            self.assertEqual(respuesta.status_code, 400, cambio)
            self.assertEqual(respuesta.json()["campos"], list(cambio))
        self.assertEqual(self.post("/api/recomendar/", {**CARACTERISTICAS, "diametro_maceta_cm": 0}).status_code, 200)

    def test_producto_id_debe_ser_entero(self):
        producto = Producto.objects.get(nombre="Lavanda")
        self.assertEqual(self.post("/api/pedidos/", {**CARACTERISTICAS, "producto_id": str(producto.id)}).status_code, 201)
        respuesta = self.post("/api/pedidos/", {**CARACTERISTICAS, "producto_id": 5.0})
        self.assertEqual(respuesta.status_code, 400)
        self.assertIn("entero", respuesta.json()["error"])

    def test_errores_de_ruta_y_metodo_en_json(self):
        for url in ["/api/", "/api/no-existe/", "/api/productos/abc/"]:
            respuesta = self.client.get(url)
            self.assertEqual(respuesta.status_code, 404, url)
            self.assertIn("error", respuesta.json())
        for metodo, url in [("get", "/api/recomendar/"), ("get", "/api/pedidos/"), ("post", "/api/productos/")]:
            respuesta = getattr(self.client, metodo)(url)
            self.assertEqual(respuesta.status_code, 405, url)
            self.assertIn("error", respuesta.json())

    def test_cors_para_flutter_web(self):
        preflight = self.client.options("/api/recomendar/", HTTP_ORIGIN="http://localhost:54321",
                                        HTTP_ACCESS_CONTROL_REQUEST_METHOD="POST")
        self.assertEqual(preflight.status_code, 204)
        self.assertEqual(preflight["Access-Control-Allow-Origin"], "http://localhost:54321")
        ajeno = self.client.get("/api/productos/", HTTP_ORIGIN="https://otro-sitio.example")
        self.assertNotIn("Access-Control-Allow-Origin", ajeno)
