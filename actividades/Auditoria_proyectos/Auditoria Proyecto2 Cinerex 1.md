# Auditoría de arquitectura — Cinerex (Django)

**Alumnos:**
> **Pérez Martínez Paulo César**
> **Martinez Enrique**
---

Para cada archivo se buscó qué mala práctica aparece, indicando el archivo y la línea donde se observa.

---

## 1. General

### 1.1 Patrones de diseño

Igual que en el proyecto anterior, se usa un framework (Django) que ya trae piezas de arquitectura resueltas, pero el equipo las deja apagadas o las reimplementa mal:

- `cinerex/settings.py:9-10` lo dice de forma casi literal en un comentario: el middleware de autenticación de Django **no está registrado**, y existe un archivo `taquilla/cadena.py` con una clase llamada `CadenaGoF` (un intento de Chain of Responsibility) que **tampoco se registró** en `MIDDLEWARE`. Es exactamente el mismo patrón del proyecto 1: la pieza correcta existe en el repositorio, pero nadie la conectó.
- Ninguna vista usa el decorador `@login_required` de Django; en su lugar, cada vista revisa la sesión "a mano" y de forma distinta.
- No hay capa de repositorio ni de servicio: las vistas y hasta los *template tags* personalizados (`taquilla/templatetags/sql_cine.py`) ejecutan SQL crudo directamente.
- Varias consultas usan `%s` dentro de la cadena de texto (no como parámetro real de `execute()`), lo cual **parece** una consulta parametrizada seguro, pero en realidad es solo texto sustituido con el operador `%` de Python antes de llegar a la base de datos — la misma inyección SQL de siempre, disfrazada de buena práctica.

### 1.2 Malas prácticas detectadas

| Archivo / carpeta | Qué se observa | Por qué es un problema |
|---|---|---|
| `cinerex/settings.py:1` | `SECRET_KEY = 'cine-inseguro-123'` escrita directamente en el código | Cualquiera con acceso al repositorio puede firmar sesiones y tokens falsos del sitio. |
| `cinerex/settings.py:2-3` | `DEBUG = True` y `ALLOWED_HOSTS = ['*']` | Con `DEBUG` activo, cualquier error muestra código fuente y variables internas al público; `ALLOWED_HOSTS = ['*']` acepta peticiones con cualquier dominio falso. |
| `cinerex/settings.py:9-10` | Comentario propio del equipo: el middleware de autenticación de Django no está registrado, y `CadenaGoF` (su propio intento de Chain of Responsibility) tampoco, aunque el archivo existe | Ninguna revisión de sesión pasa por un lugar central; cada vista decide por su cuenta cómo (o si) valida al usuario. |
| `cinerex/settings.py:12` | Contraseña de la base de datos (`'password'`) escrita directamente en `DATABASES` | Igual que en el proyecto anterior: el secreto de producción queda expuesto en el código fuente en vez de una variable de entorno. |
| `taquilla/views.py:10` | `f"SELECT id, tipo FROM socios WHERE correo='{u}' AND pin='{p}'"` con `u`/`p` tomados directo del formulario | Inyección SQL clásica: un correo especial permite alterar la consulta y entrar sin conocer el PIN real. |
| `taquilla/views.py:13-16` | Se guarda `request.session['sid']` **y además** dos cookies (`cine_ok`, `admin_bypass` si el socio es `staff`) | Dos mecanismos de identidad al mismo tiempo; la cookie la controla el navegador, no el servidor. |
| `taquilla/views.py:22` | `if request.COOKIES.get('admin_bypass'): request.session['sid']=1` | Puerta trasera idéntica a la del proyecto 1: basta esa cookie (regalada a cualquier `staff` en el login) para entrar como el socio 1. |
| `taquilla/views.py:25-27` | Ciclo de 9 llamadas HTTP a `http://127.0.0.1/mods/N` con excepciones ignoradas (`except: pass`) | Trabajo remoto repetido sin ningún efecto claro en la vista; ralentiza la página y oculta cualquier falla real detrás de un `pass` silencioso. |
| `taquilla/views.py:32-35` | Dentro del `for` que recorre películas se abre un segundo cursor y se hace una consulta nueva de horarios por cada película | Problema N+1: con 50 películas en cartelera son 50 consultas extra para armar una sola página. |
| `taquilla/views.py:41-45` (`funcion_old`) | Segunda versión de la vista de función, con SQL armado por concatenación directa de `fid` | Duplicado de `funcion()` con inyección SQL, sin indicar cuál versión es la vigente — mismo patrón que `menu_old` del proyecto 1. |
| `taquilla/views.py:56-60` | `if/elif` de 6 casos casi idénticos para el precio según tipo de boleto (`3d`, `imax`, `vip`, `nino`, `maraton`) | Agregar un tipo de función nueva obliga a tocar este mismo bloque. |
| `taquilla/views.py:61-73` | `if/elif` de 3 métodos de pago, con una llamada HTTP a una pasarela externa embebida dentro del mismo bloque | Mismo problema del proyecto 1: agregar un método de pago es copiar y pegar dentro de la vista. |
| `taquilla/views.py:72,75,76,77` | `'...%s...' % (precio, socio)` armado con el operador `%` de Python **antes** de pasarlo a `execute()` | Parece una consulta parametrizada (usa `%s`), pero en realidad los valores ya están pegados como texto cuando `execute()` los recibe: es la misma inyección SQL de siempre, solo que disfrazada. |
| `taquilla/views.py:74-77` | Se inserta el boleto, se actualiza el asiento y se inserta el combo de snacks como tres sentencias sueltas, sin transacción | Si falla la segunda o tercera instrucción, queda un boleto cobrado sin asiento marcado como ocupado, o sin el combo asociado. |
| `taquilla/views.py:78-79` | `send_mail(...)` se llama directo dentro de la vista `comprar`, acoplando el cobro con el detalle de cómo se notifica | Si mañana se necesita también un SMS o una notificación push, hay que volver a tocar esta misma función. |
| `taquilla/views.py:80` | `return HttpResponse("<script>alert('no recargue');location='/';</script>")` como única defensa contra doble envío | No es un control real: un doble clic o un reintento de red puede generar un doble cobro y un doble boleto para el mismo asiento. |
| `taquilla/views.py:86` | `if not request.session.get('sid') and not request.COOKIES.get('admin_bypass'): return HttpResponseForbidden()` | Vuelve a aceptar la cookie de puerta trasera como válida en una tercera vista distinta (`membresia`). |
| `taquilla/templatetags/sql_cine.py:9` | `c.execute("SELECT codigo, ocupado FROM asientos WHERE funcion_id=%s"%fid)` | Mismo patrón: el `%s` se sustituye con el operador `%` de Python antes de llegar a `execute()`, por lo que `fid` viaja como texto sin escapar — inyección SQL dentro de un *template tag*. |
| `taquilla/templatetags/sql_cine.py:12` | El HTML de cada asiento se arma con `%` y se envuelve en `mark_safe()` | `mark_safe` le dice a Django "no escapes esto"; si `codigo` llegara a contener HTML/JS, se ejecutaría tal cual en la página. |
| `taquilla/templatetags/sql_cine.py:21-23` | Dentro del `for` de películas se ejecuta una consulta `COUNT(*)` nueva por cada una | Mismo problema N+1 ya visto, ahora dentro de un *template tag* en lugar de una vista. |
| `static/css/ruido.css` | 90 clases (`mod_caja_0` a `mod_caja_89`) casi idénticas, cambiando solo el `padding` | Código muerto que solo infla el archivo; el mismo patrón exacto del proyecto 1 (probablemente copiado tal cual). |
| `docs/ARQUITECTURA_OFICIAL.md` y `docs/modelo_datos.txt` | Describen un sistema de **logística portuaria** ("patio de contenedores", "turnos de grúa"), con tablas `Contenedor_V2`, `Grúa_Activa`, y prohíben explícitamente usar las tablas reales (`peliculas`, `funciones`, `boletos`) | Documentación que describe un dominio de negocio completamente distinto (puerto marítimo) al que en realidad implementa el código (venta de boletos de cine) — el mismo problema del proyecto 1, con un giro irónico: el documento incluso prohíbe "reimplementar LoginRequired" cuando el propio proyecto ni siquiera activó el middleware de autenticación de Django. |

### 1.3 ¿Se puede corregir poco a poco, o conviene rehacerlo desde cero?

**Se recomienda rehacer la arquitectura desde cero**, apoyándose en el código actual solo como referencia de las reglas de negocio (precios por tipo de función, cómo se marca un asiento como ocupado, qué pasa al comprar snacks), pero no como base para editar línea por línea.

Lo que sí se puede reutilizar: el modelo de datos base una vez depurado, las reglas de precio por tipo de sala, y el flujo general de "elegir asiento → cobrar → marcar ocupado → avisar".

---

## 2. Misión 1 — Un framework con autenticación "apagada" no es un patrón

| # | Problema detectado en el proyecto | Capa afectada | Patrón(es) que lo resuelve | Por qué ese y no el patrón parecido que suele confundirse | Cuándo NO conviene aplicarlo |
|---|---|---|---|---|---|
| 1 | El middleware de autenticación de Django y la clase propia `CadenaGoF` existen pero **ninguno está registrado** en `MIDDLEWARE`; la revisión de sesión se repite distinta en `login`, `cartelera` y `membresia`, cada una aceptando la cookie `admin_bypass` | Políticas transversales | **Front Controller** (el despachador de Django, ya presente) **+ Chain of Responsibility** (activar `CadenaGoF` o el middleware nativo en el pipeline real) | Decorator, con el que se suele confundir, siempre deja pasar la petición envolviéndola; la cadena necesita poder **detener** la petición si la sesión no es válida | Si el sitio tuviera 2-3 páginas públicas fijas sin planes de crecer, no se justifica el esfuerzo de centralizar |
| 2 | `comprar()` tiene un `if/elif` de 6 tipos de boleto para el precio y otro de 3 métodos de pago, con una llamada HTTP a una pasarela externa embebida en el mismo bloque | Aplicación/dominio + Integración | **Strategy** (elegir el algoritmo de precio/cobro) **+ Adapter** (traducir la petición/respuesta de la pasarela a un formato interno común) | Factory, con el que se suele confundir, sirve para decidir qué objeto crear; aquí el socio ya eligió tipo de función y método de pago en el formulario, lo que cambia es el algoritmo de cálculo/cobro | Si solo existiera un tipo de sala y un método de pago, sin planes de agregar más, esta capa sería complejidad de más |
| 3 | `sql_cine.py` (los *template tags*) y las vistas `cartelera`/`funcion_old`/`comprar` ejecutan SQL crudo directo, mezclando presentación y acceso a datos incluso dentro de las plantillas | Presentación + Datos | **Repository + Service Layer** | Facade, con el que se suele confundir, agrupa llamadas a un subsistema para simplificar su uso, pero no resuelve que la plantilla contenga SQL; Repository es la pieza que aísla cómo se consultan los datos | Si fuera una sola consulta simple, usada una única vez sin repetirse en otra plantilla, no se justifica una capa de repositorio completa |
| 4 | `comprar()` inserta el boleto, actualiza el asiento y da de alta el combo como tres pasos sueltos sin transacción, y la única defensa contra doble envío es un `alert()` de "no recargue" | Aplicación/dominio + Datos | **Idempotencia (clave de operación) + Unit of Work** (Django ya trae `transaction.atomic`, sin usar) | Arreglar solo el mensaje al usuario no evita que la misma petición se ejecute dos veces por un doble clic o un reintento de red | Si el cobro fuera un único paso completamente síncrono y el banco garantizara que un mismo folio nunca se cobra dos veces, esta capa sería innecesaria |
| 5 | `static/css/ruido.css` tiene 90 clases casi idénticas, cada una cambiando solo el `padding` | Presentación (frontend) | **Valor único parametrizado** (variable/mixin de espaciado, no un patrón GoF) | Strategy tiene sentido cuando el comportamiento cambia entre variantes; aquí solo cambia un número, basta un parámetro | Si cada "caja" tuviera además un comportamiento visual realmente distinto, ahí sí convendría algo más flexible |
| 6 | `send_mail(...)` se llama directo dentro de `comprar()`, acoplando la compra del boleto al detalle de cómo se notifica | Aplicación/dominio | **Observer** | Mediator, con el que se suele confundir, coordina objetos que se comunican entre sí en ambos sentidos; aquí solo se necesita difundir un evento a varios interesados que no se hablan entre ellos | Si solo existiera un único correo fijo, sin planes de agregar más canales (SMS, push), añadir Observer sería complejidad de más |

---

## 3. Misión 2 — Una petición, varios patrones

### 3.1 Lo que hace el código

La compra de un boleto (`/comprar/`) pasa por una sola vista (`comprar`), pero esa vista mezcla en un solo bloque: cálculo de precio, selección de método de pago, llamada a una pasarela externa, tres escrituras a base de datos sin transacción y el envío de un correo — todo sin revisar antes si la sesión del socio es válida.

### 3.2 Camino corregido a seguir

| Paso | Qué ocurre | Tipo de componente | Patrón que representa en ese momento |
|---|---|---|---|
| 1 | El socio elige función, asiento y método de pago en el formulario, y presiona "Pagar" | Vista / pantalla del cliente | Representación de la interfaz (fuera del alcance de esta tabla de backend) |
| 2 | El formulario se envía como `POST /comprar/` hacia el servidor | Petición HTTP | — |
| 3 | La petición entra por el despachador nativo de Django (activando el pipeline real de `MIDDLEWARE`) | Enrutador de entrada | **Front Controller** |
| 4 | Antes de llegar a la lógica de compra se revisa, en orden: que la sesión sea válida, que el asiento siga libre, y se registra el intento en bitácora | Middleware / filtros previos | **Chain of Responsibility** (activando `CadenaGoF` o el middleware de auth de Django) |
| 5 | Una vista delgada recibe los datos ya validados y llama al caso de uso, sin decidir reglas de negocio por su cuenta | Controlador de la operación | Controlador de la operación (recibe la entrada, no decide el negocio) |
| 6 | Se invoca la operación `comprarBoleto(socioId, funcionId, asiento, tipo, pago)` | Capa de casos de uso | **Service Layer** |
| 7 | Dentro de esa operación se elige el algoritmo de precio según el tipo de función, y el algoritmo de cobro según el método de pago | Selector de algoritmo | **Strategy** |
| 8 | Antes de ejecutar el cobro, se revisa una clave que identifica esta operación en particular, para que un doble clic no genere un segundo boleto para el mismo asiento | Verificación de operación repetida | **Idempotencia** |
| 9 | Se traduce la petición de cobro al formato que entiende la pasarela externa, y su respuesta a un formato interno común | Conector hacia el proveedor externo | **Adapter** |
| 10 | La pasarela procesa el cobro y responde con un código de resultado | Servicio externo | — |
| 11 | Si el cobro fue exitoso, se guardan el boleto, el cambio de estado del asiento a "ocupado" y el alta del combo de snacks como una sola operación conjunta: o se guardan las tres cosas, o no se guarda ninguna | Persistencia de datos | **Repository + Unit of Work** (`transaction.atomic` de Django) |
| 12 | Una vez confirmada la compra, se avisa a quienes deben reaccionar (correo al socio, actualización de puntos, aviso a caja) sin que la compra tenga que conocer a cada uno por nombre | Notificación de eventos internos | **Observer** |
| 13 | Si la pasarela tarda demasiado o falla de forma repetida, se deja de insistir tras un tiempo límite, sin bloquear el resto del sistema (la cartelera, que no depende del banco, sigue funcionando) | Protección ante fallas del proveedor externo | **Timeout + Circuit Breaker** |
| 14 | Se arma la respuesta para el socio confirmando el boleto y el asiento asignado, sin depender de un mensaje de "no recargue" como única medida de seguridad | Formato de salida | Plantilla de salida (adaptada al tipo de cliente que la pidió) |

---

## 4. Misión 3 — Políticas transversales

### a) Cuándo y por qué conviene una sola puerta de entrada (Front Controller)

En el proyecto actual, la revisión de sesión aparece distinta en `login` (regala la cookie `admin_bypass` a cualquier `staff`), en `cartelera` y `membresia` (aceptan esa misma cookie como válida), y en `funcion`/`funcion_old` (no revisan nada). Cuando la misma tarea se repite copiada en cada vista, tarde o temprano una copia queda incompleta, como pasó aquí. Conviene una sola puerta de entrada cuando varias rutas necesitan pasar por las mismas revisiones antes de ejecutarse.

### b) Qué ya traen los marcos de trabajo modernos para esto

Django ya trae su propio sistema de middleware y de autenticación (`AuthenticationMiddleware`, decorador `@login_required`). En este proyecto **el equipo hasta escribió su propia versión** (`CadenaGoF`) en vez de usar o activar lo que el framework ya ofrece, y terminó sin registrar ninguna de las dos opciones. El problema no es falta de herramientas: es no conectarlas.

### c) Orden correcto de la revisión previa

1. *Autenticación* — confirmar quién es el socio que hace la petición (sin aceptar cookies que el propio navegador puede fabricar).
2. *Validación de negocio* — confirmar que el asiento sigue libre y que la función no ha pasado.
3. *Bitácora* — dejar constancia de que la petición ocurrió.
4. *Caso de uso* — ejecutar la compra en sí.

Cobrar antes de autenticar es un error grave: si el cobro ocurre antes de confirmar la identidad del socio, y esa confirmación falla después, no hay manera limpia de saber a quién pertenece ese dinero ni cómo revertirlo con seguridad.

### d) Qué NO debe ir dentro de esa cadena de filtros previos

No deben colocarse ahí las decisiones específicas de la compra (qué precio corresponde al tipo de función, qué pasarela usar según el método de pago). Esas reglas pertenecen al caso de uso concreto (`comprarBoleto`) y deben vivir dentro de él, no en un filtro genérico que se ejecuta para todas las peticiones por igual.
