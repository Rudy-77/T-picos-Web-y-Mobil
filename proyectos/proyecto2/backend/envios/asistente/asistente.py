"""Responde al comprador según su intención; no decide envíos, eso lo hace el recomendador."""

import re
import unicodedata

from .. import reglas
from ..tipos_envio import TIPOS_ENVIO
from .clasificador import obtener_clasificador
from .texto import extraer_folio

# Bajo esta confianza respondo no_se; el valor lo elegí con validación cruzada.
UMBRAL_CONFIANZA = 0.40
MAX_PRODUCTOS = 5

PALABRAS_VACIAS = {
    "tienen", "tiene", "tengan", "venden", "vende", "hay", "busco", "buscar", "quiero", "quisiera",
    "necesito", "una", "un", "unos", "unas", "el", "la", "los", "las", "de", "del", "para", "por",
    "con", "sin", "que", "qué", "me", "mi", "mis", "algo", "alguna", "algun", "cual", "cuál",
    "cuanto", "cuánto", "cuesta", "precio", "stock", "ver", "muestrame", "muéstrame", "lista",
    "producto", "productos", "catalogo", "catálogo", "disponibles", "disponible", "vivero", "venta",
    "cuales", "cuáles", "cuantas", "cuántas", "cuantos", "cuántos", "todo", "todos", "todas", "cosas",
    "enseñame", "enséñame", "muestra", "ofrecen", "ofrece", "manejan", "comprar", "puedo", "aqui", "aquí",
    "recomiendas", "recomienda", "recomiendan", "existencia", "existen", "hola", "tienes", "tenemos",
    "y", "o", "en", "a", "al", "es", "son", "quedan", "les", "se", "si", "sí", "tipo", "tipos",
    "manejan", "manejas", "dame", "dime", "favor", "porfa", "hola", "buenas", "grandes", "grande",
}

CATEGORIAS = ("planta", "maceta", "sustrato", "fertilizante")
PLURALES = {"planta": "plantas", "maceta": "macetas", "sustrato": "sustratos", "fertilizante": "fertilizantes"}
SINONIMOS = {"abono": "fertilizante", "tierra": "sustrato", "árbol": "frutal"}

ENVIOS_NOMBRES = {"estandar": "estándar", "protegido": "protegido", "humedad": "humedad", "termico": "térmico"}

LIMITES_TEXTO = {
    "temperatura_min_c": "temperatura mínima de destino: {} °C",
    "temperatura_max_c": "temperatura máxima de destino: {} °C",
    "dias_max": "hasta {} días de tránsito",
    "altura_max_cm": "plantas de hasta {} cm",
    "valor_min_mxn": "valor declarado mínimo: {} MXN",
}

MENU = ("Puedo rastrear tu pedido con su folio, explicarte por qué te salió un envío, "
        "buscar productos del catálogo y contarte cómo son los tipos de envío.")


def sin_acentos(texto):
    descompuesto = unicodedata.normalize("NFD", texto.lower())
    return "".join(c for c in descompuesto if unicodedata.category(c) != "Mn")


def terminos_busqueda(mensaje):
    """Palabras útiles para buscar en el catálogo, en singular simple (helechos -> helecho)."""
    palabras = re.findall(r"[a-záéíóúüñ]+", mensaje.lower())
    terminos = []
    for palabra in palabras:
        if palabra in PALABRAS_VACIAS or len(palabra) < 3:
            continue
        if palabra.endswith("es") and len(palabra) > 5:
            palabra = palabra[:-2]
        elif palabra.endswith("s") and len(palabra) > 3:
            palabra = palabra[:-1]
        palabra = SINONIMOS.get(palabra, palabra)
        if palabra not in terminos:
            terminos.append(palabra)
    return terminos


def plantas_primero(productos):
    return sorted(productos, key=lambda p: CATEGORIAS.index(p["categoria"]))


def buscar_productos(mensaje, listar_productos):
    """Devuelve (productos, categoria, por_nombre); las palabras de categoría filtran, no se buscan como texto."""
    terminos = terminos_busqueda(mensaje)
    categorias = [t for t in terminos if t in CATEGORIAS]
    categoria = categorias[0] if categorias else ""
    terminos = [t for t in terminos if t not in CATEGORIAS]
    if not terminos:
        return plantas_primero(listar_productos("", categoria)), categoria, False

    aciertos = {}
    productos = {}
    for termino in terminos:
        for producto in listar_productos(termino, categoria):
            aciertos[producto["id"]] = aciertos.get(producto["id"], 0) + 1
            productos[producto["id"]] = producto
    if not productos and categoria:
        return plantas_primero(listar_productos("", categoria)), categoria, False
    orden = sorted(aciertos, key=lambda id_: (-aciertos[id_], productos[id_]["nombre"]))
    return [productos[id_] for id_ in orden], categoria, True


def texto_catalogo(productos, categoria, por_nombre):
    total = len(productos)
    if por_nombre:
        texto = f"Encontré {total} producto(s) del catálogo."
    elif categoria:
        nombres = ", ".join(p["nombre"] for p in productos)
        texto = f"Tenemos {total} {categoria if total == 1 else PLURALES[categoria]} en el catálogo: {nombres}."
    else:
        por_categoria = {c: sum(1 for p in productos if p["categoria"] == c) for c in CATEGORIAS}
        conteo = ", ".join(f"{n} {c if n == 1 else PLURALES[c]}" for c, n in por_categoria.items() if n)
        texto = f"Tenemos {total} productos en el catálogo: {conteo}. Pregúntame por una categoría o por un nombre."
    if total > MAX_PRODUCTOS:
        texto += f" Te muestro {MAX_PRODUCTOS} aquí; el resto está en el catálogo."
    return texto


def resumen_pedido(pedido):
    resultado = pedido["resultado"]
    plan = resultado["plan"]
    return {
        "folio": pedido["folio"],
        "creado_en": pedido["creado_en"],
        "producto": pedido["producto"]["nombre"] if pedido["producto"] else None,
        "cantidad": pedido["cantidad"],
        "envio": resultado["envio"],
        "corregido_por_reglas": resultado["corregido_por_reglas"],
        "plan": {
            "empaque": plan["empaque"],
            "dias": plan["dias"],
            "costo_estimado_mxn": plan["costo_estimado_mxn"],
            "riego_sugerido": plan["riego_sugerido"],
        },
    }


def nombre_envio(envio):
    return ENVIOS_NOMBRES.get(envio, envio)


def fecha_del_folio(folio):
    # Tomo la fecha del folio, que es la local de registro; creado_en viene en UTC.
    dia = folio.split("-")[1]
    return f"{dia[:4]}-{dia[4:6]}-{dia[6:]}"


def texto_rastreo(resumen):
    producto = f" de {resumen['producto']} (x{resumen['cantidad']})" if resumen["producto"] else ""
    plan = resumen["plan"]
    return (f"Encontré el pedido {resumen['folio']}{producto}, registrado el {fecha_del_folio(resumen['folio'])}. "
            f"Va en envío {nombre_envio(resumen['envio'])}: {plan['empaque']}, {plan['dias']} día(s) estimados, "
            f"costo estimado {plan['costo_estimado_mxn']:.2f} MXN. "
            "El sistema guarda el pedido, pero no tiene seguimiento de paquetería.")


def texto_explicacion(pedido):
    """Explica con lo que quedó guardado en el pedido; no recalcula nada."""
    resultado = pedido["resultado"]
    envio = nombre_envio(resultado["envio"])
    preferido = nombre_envio(resultado["preferido_por_modelo"])
    if resultado["corregido_por_reglas"]:
        motivo = next((d["motivo"] for d in resultado["descartados"]
                       if d["envio"] == resultado["preferido_por_modelo"]), "no cumplía las reglas")
        partes = [f"Tu pedido {pedido['folio']} salió en envío {envio}. El modelo prefería {preferido}, "
                  f"pero las reglas del vivero lo descartaron porque {motivo}."]
        if resultado["sin_opcion_valida"]:
            partes.append("Ningún envío cumplía las reglas; se usó este como respaldo y conviene revisar el pedido con el encargado.")
        else:
            partes.append(f"Por eso se pasó al siguiente envío posible; el modelo le daba una confianza de {resultado['confianza']:.0%}.")
    else:
        partes = [f"Tu pedido {pedido['folio']} salió en envío {envio}, con confianza de {resultado['confianza']:.0%}. "
                  "Es lo que prefería el modelo y ninguna regla lo impedía."]
    otros = [f"{nombre_envio(d['envio'])}: {d['motivo']}" for d in resultado["descartados"]
             if d["envio"] != resultado["preferido_por_modelo"] or not resultado["corregido_por_reglas"]]
    if otros:
        partes.append(f"Otros envíos que las reglas descartaron: {'; '.join(otros)}.")
    partes.append(f"Riego: {resultado['plan']['riego_sugerido']}")
    return " ".join(partes)


def describir_limites(envio):
    limites = reglas.LIMITES[envio]
    return "; ".join(LIMITES_TEXTO[llave].format(valor) for llave, valor in limites.items())


def texto_envios(mensaje):
    pedido = sin_acentos(mensaje)
    mencionados = [e for e in TIPOS_ENVIO if e in pedido]
    elegidos = mencionados or list(TIPOS_ENVIO)
    lineas = []
    for envio in elegidos:
        linea = f"{ENVIOS_NOMBRES[envio].capitalize()}: {TIPOS_ENVIO[envio].descripcion}."
        limites = describir_limites(envio)
        if limites:
            linea += f" Límites: {limites}."
        lineas.append(linea)
    return " ".join(lineas)


def elegir_folio(mensaje, contexto):
    """Folio del mensaje; si no hay, el último folio que recordó la app."""
    folio = extraer_folio(mensaje)
    if folio:
        return folio, False
    recordado = extraer_folio((contexto or {}).get("ultimo_folio", ""))
    return recordado, recordado is not None


def responder_folio(intencion, mensaje, contexto, buscar_pedido):
    folio, del_contexto = elegir_folio(mensaje, contexto)
    if folio is None:
        accion = "rastrear" if intencion == "rastreo_folio" else "explicar"
        return {"respuesta": f"Para {accion} tu pedido necesito el folio, por ejemplo VIV-20261123-0001."}

    pedido = buscar_pedido(folio)
    if pedido is None:
        return {"respuesta": f"No encontré un pedido con el folio {folio}. Revisa que esté completo.",
                "folio": folio}

    texto = texto_rastreo(resumen_pedido(pedido)) if intencion == "rastreo_folio" else texto_explicacion(pedido)
    if del_contexto:
        texto = f"Usé tu último folio, {folio}. {texto}"
    return {"respuesta": texto, "folio": folio, "pedido": resumen_pedido(pedido)}


def responder(mensaje, contexto, buscar_pedido, listar_productos, clasificador=None):
    clasificador = clasificador or obtener_clasificador()
    intencion = clasificador.clasificar(mensaje)
    nombre = intencion.nombre if intencion.confianza >= UMBRAL_CONFIANZA else "no_se"
    datos = {"intencion": nombre, "confianza": intencion.confianza}

    if nombre == "saludo":
        datos["respuesta"] = f"¡Hola! Soy el asistente del vivero. {MENU}"
    elif nombre == "despedida_gracias":
        datos["respuesta"] = "¡Con gusto! Aquí estaré si necesitas algo más."
    elif nombre in ("rastreo_folio", "explicar_recomendacion"):
        datos.update(responder_folio(nombre, mensaje, contexto, buscar_pedido))
    elif nombre == "buscar_producto":
        productos, categoria, por_nombre = buscar_productos(mensaje, listar_productos)
        if productos:
            datos["respuesta"] = texto_catalogo(productos, categoria, por_nombre)
            datos["productos"] = productos[:MAX_PRODUCTOS]
        else:
            datos["respuesta"] = "No encontré productos con esa búsqueda. Prueba con otro nombre o revisa el catálogo."
    elif nombre == "recomendar_envio":
        datos["respuesta"] = ("El tipo de envío lo decide el recomendador del vivero con los datos de tu planta "
                              "y del destino; yo no lo elijo. Abre el formulario de nuevo envío para calcularlo.")
        datos["accion"] = {"tipo": "abrir_formulario_envio", "endpoint": "/api/recomendar/"}
    elif nombre == "info_envios":
        datos["respuesta"] = texto_envios(mensaje)
    else:
        datos["intencion"] = "no_se"
        datos["respuesta"] = f"No estoy seguro de haberte entendido o no tengo esa información. {MENU}"
    return datos
