# Auditoría de arquitectura — TallerPro (Express)

**Alumnos:**
> **Pérez Martínez Paulo César**
> **Martinez Enrique**
---

Para cada archivo se buscó qué mala práctica aparece, indicando el archivo y la línea donde se observa.

---

## 1. General

### 1.1 Patrones de diseño

Este proyecto es distinto a los tres anteriores en un punto importante: **sí existe una Chain of Responsibility real y bien escrita** (`cadena/Handler.js`, con `AuthHandler` y `BitacoraHandler` envolviendo a `CobroOrden`), y sí está conectada — se usa de verdad en `app.post('/nueva', ...)`. No es un intento a medias ni una clase muerta.

El problema no es que falte el patrón, sino que se aplicó de forma incompleta:

- Solo protege la ruta `/nueva`. Las rutas `/`, `/login`, `/entrega` e `/inventario` **no pasan por esa cadena**: cada una reimplementa (o de plano omite) su propia revisión de sesión.
- El primer eslabón de la cadena que sí funciona, `AuthHandler` (`cadena/Handler.js:8`), **también acepta la cookie de puerta trasera** `admin_bypass`. Es decir: el patrón está bien construido, pero uno de sus eslabones tiene el mismo error de seguridad que aparece sin patrón en el resto de las rutas.
- Express ya ofrece `app.use()` para registrar middleware una sola vez y que aplique a todas las rutas que se necesite; en vez de usarlo para la cadena, el equipo la instancia a mano (`new AuthHandler(new BitacoraHandler(new CobroOrden()))`) dentro de una sola ruta.
- También se reimplementa a mano el análisis de cookies (`app.js:11`) en vez de usar el paquete estándar `cookie-parser`, ya disponible en el ecosistema de Express.

### 1.2 Malas prácticas detectadas

| Archivo / carpeta | Qué se observa | Por qué es un problema |
|---|---|---|
| `app.js:10` | `session({ secret: 'password', ... })` | El secreto de la sesión es la palabra literal `password` — la misma que la contraseña de la base de datos (`app.js:12`) — reutilizando un valor débil para dos propósitos distintos. |
| `app.js:11` | Middleware casero que parte `req.headers.cookie` a mano para armar `req.cookies` | Reimplementa algo que el paquete estándar `cookie-parser` ya resuelve de forma probada; cualquier caso raro de formato de cookie (espacios, `=` dentro del valor) puede romper este parseo manual. |
| `cadena/Handler.js:8` | `if (req.cookies?.admin_bypass) req.session.tid = 1;` dentro de `AuthHandler`, el único eslabón de autenticación que sí está conectado | La cadena está bien construida como patrón, pero ese eslabón contiene la misma puerta trasera de los tres proyectos anteriores: cualquiera con esa cookie entra sin validar nada más. |
| `app.js:59-62` (`/`) | Revisión de sesión distinta e independiente a la de `AuthHandler`, que también acepta `admin_bypass` | La ruta principal no reutiliza la cadena que ya existe; vuelve a escribir (peor) la misma revisión, duplicando el error de seguridad en un segundo lugar. |
| `app.js:51` | `"SELECT id, rol FROM personal WHERE correo='"+req.body.correo+"' AND clave='"+req.body.clave+"'"` armada por concatenación | Inyección SQL clásica en el login. |
| `app.js:55` | `'admin_bypass='+(rows[0].rol==='jefe'?'1':'0')` — la cookie se manda **siempre**, incluso con valor `'0'` para quien no es jefe | Aunque el valor sea `'0'`, la lógica que la lee (`if (req.cookies.admin_bypass)`) solo comprueba que la cookie *exista*, no su valor — cualquier cookie `admin_bypass` (incluso `admin_bypass=0`) activa el bypass. |
| `app.js:64` | Ciclo de 8 llamadas HTTP a `http://127.0.0.1/mod/i` con `catch(e){}` vacío | El mismo patrón de trabajo remoto repetido e ignorado que ya apareció en los tres proyectos anteriores. |
| `app.js:66-68` | La ruta `/` arma el HTML completo con `res.send('...'+JSON.stringify(ords)+...)`, sin usar ninguna plantilla | No hay separación entre presentación y datos: el HTML, el JSON crudo de la base de datos y la lógica de sesión viven en la misma función. |
| `CobroOrden.manejar` (`app.js:19-23`) | `if/elif` de 5 casos casi idénticos para el costo según tipo de servicio (`frenos`, `motor`, `eléctrico`, `hojalatería`, `afinación`) | Agregar un tipo de servicio nuevo obliga a tocar este mismo bloque. |
| `CobroOrden.manejar` (`app.js:26-35`) | `if/elif` de 3 métodos de pago, uno de ellos con una llamada `axios.post` a una pasarela externa embebida en el mismo bloque, y otro (`credito_cliente`) que actualiza el saldo del cliente por concatenación directa (`"...saldo + "+costo+" WHERE id="+req.body.cliente`) | Mezcla de reglas de negocio y llamada externa en el mismo lugar, más una inyección SQL adicional en el manejo de crédito de cliente. |
| `CobroOrden.manejar` (`app.js:37-39`) | Se obtiene una conexión dedicada del pool (`pool.getConnection()`), pero las tres escrituras (orden, refacciones, mecánico) se ejecutan sueltas, sin `BEGIN`/`COMMIT` ni manejo de transacción | Tener una conexión dedicada es el primer paso correcto para una transacción, pero al no envolver las tres escrituras en una, si la segunda o tercera falla, la orden ya quedó marcada como pagada sin refacción registrada o sin marcar ocupado al mecánico. |
| `app.js:44` | `res.send("<script>alert('no recargue');location='/';</script>")` como única defensa contra doble envío | Mismo problema de los tres proyectos anteriores: no es un control real contra un doble clic o un reintento de red. |
| `app.js:84` | Dentro del `for` de refacciones en `/inventario` se ejecuta una consulta nueva de `cat_refacciones` por cada fila, armada por concatenación de `r.tipo` | Problema N+1 combinado con inyección SQL, dentro de una ruta que ni siquiera pasa por la cadena de autenticación. |
| `app.js:94-95` (`/entrega`) | Dos `UPDATE` armados por concatenación directa de `req.query.id`, sin pasar por ninguna revisión de sesión | Inyección SQL en una ruta pública que además marca órdenes como entregadas y libera mecánicos sin ninguna autenticación. |
| `app.old.js` | Archivo completo que solo re-exporta `app.js`, con el comentario `// copia de 2022, no borrar por si acaso` | Archivo duplicado que no aporta nada funcional, pero queda ahí "por si acaso"; el mismo hábito de acumular versiones viejas sin decidir cuál es la vigente que ya apareció en los proyectos anteriores. |
| `public/css/ruido.css` | 90 clases (`mod_caja_0` a `mod_caja_89`) casi idénticas, cambiando solo el `padding` | El mismo archivo de código muerto que ya apareció en los tres proyectos anteriores. |
| `documentacion/SISTEMA.txt` | Describe una **clínica dental** ("las órdenes son tratamientos", "los mecánicos son odontólogos"), prohíbe explícitamente "implementar Chain of Responsibility con clases", y afirma que ya existe un Observer de recordatorios "tras COMMIT" | Documentación de un dominio de negocio distinto (clínica dental) al real (taller mecánico); y, a diferencia de los tres proyectos anteriores (donde el documento prohibía justo la mala práctica cometida), aquí prohíbe **la única cosa que el proyecto sí hizo bien** (la cadena de clases), y además miente sobre un `COMMIT` que no existe en ningún lado del código. |

### 1.3 ¿Se puede corregir poco a poco, o conviene rehacerlo desde cero?

**Se recomienda rehacer la arquitectura desde cero**, apoyándose en el código actual solo como referencia de las reglas de negocio (costos por tipo de servicio, qué pasa al entregar una orden), pero no como base para editar línea por línea. La única pieza que sí vale la pena conservar como *idea* (no como código, por el bypass que contiene) es la estructura de la cadena `AuthHandler → BitacoraHandler → CobroOrden`: el diseño es correcto, solo falta aplicarlo de forma uniforme y sin el atajo de la cookie.

Lo que sí se puede reutilizar: el modelo de datos base una vez depurado, las reglas de costo por tipo de servicio, y el flujo general de "abrir orden → cobrar → registrar refacción → liberar mecánico al entregar".

---

## 2. Misión 1 — Un patrón bien escrito, aplicado a medias

| # | Problema detectado en el proyecto | Capa afectada | Patrón(es) que lo resuelve | Por qué ese y no el patrón parecido que suele confundirse | Cuándo NO conviene aplicarlo |
|---|---|---|---|---|---|
| 1 | La cadena `AuthHandler → BitacoraHandler → CobroOrden` está bien construida, pero solo protege `/nueva` (armada a mano en esa única ruta); `/`, `/login`, `/entrega` e `/inventario` no la usan, y el propio `AuthHandler` acepta la cookie `admin_bypass` | Políticas transversales | **Front Controller** (registrar la cadena como middleware de Express con `app.use()`, aplicándola a todas las rutas que lo necesiten) **+ corregir el eslabón** (quitar el bypass de `AuthHandler`) | A diferencia de los tres proyectos anteriores, aquí Chain of Responsibility **sí está bien implementado como estructura de clases**; el problema no es el patrón en sí, sino que Express ya ofrece un mecanismo (`app.use()`) para aplicarlo de forma global, y el equipo prefirió instanciarlo a mano en un solo lugar | Si la aplicación tuviera de verdad solo una ruta que proteger, instanciar la cadena ahí mismo (sin volverla middleware global) sería razonable |
| 2 | `CobroOrden` tiene un `if/elif` de 5 tipos de servicio para el costo, y otro de 3 métodos de pago con una llamada `axios.post` embebida en el mismo bloque | Aplicación/dominio + Integración | **Strategy** (elegir el algoritmo de costo/cobro) **+ Adapter** (traducir la petición/respuesta de la pasarela externa a un formato interno común) | Factory, con el que se suele confundir, sirve para decidir qué objeto crear; aquí el cliente ya eligió tipo de servicio y método de pago en el formulario, lo que cambia es el algoritmo de cálculo/cobro | Si el taller solo ofreciera un tipo de servicio y un método de pago, sin planes de crecer, esta capa sería complejidad de más |
| 3 | La ruta `/` arma el HTML completo a mano con `res.send()` mezclando JSON crudo de la base de datos, y `/inventario` hace una consulta nueva por cada fila dentro de un `for` | Presentación + Datos | **Repository + Service Layer** (más una plantilla real en vez de concatenar HTML a mano) | Facade, con el que se suele confundir, agrupa llamadas a un subsistema para simplificar su uso, pero no resuelve que la ruta contenga SQL y armado de HTML mezclados; Repository es la pieza que aísla cómo se consultan los datos | Si fuera una sola consulta simple, usada una única vez, no se justifica una capa de repositorio completa |
| 4 | `CobroOrden` obtiene una conexión dedicada del pool pero ejecuta sus tres escrituras sin transacción, y la única defensa contra doble envío es un `alert()` de "no recargue" | Aplicación/dominio + Datos | **Idempotencia (clave de operación) + Unit of Work** (usar `BEGIN`/`COMMIT` con la conexión ya obtenida) | Tener la conexión dedicada es necesario pero no suficiente: sin una transacción explícita, un fallo a la mitad deja datos inconsistentes igual que si no se hubiera pedido la conexión dedicada | Si las tres escrituras fueran completamente independientes entre sí (ninguna depende del éxito de la otra), envolverlas en una sola transacción sería innecesario |
| 5 | `public/css/ruido.css` tiene 90 clases casi idénticas, cada una cambiando solo el `padding` | Presentación (frontend) | **Valor único parametrizado** (variable/mixin de espaciado, no un patrón GoF) | Strategy tiene sentido cuando el comportamiento cambia entre variantes; aquí solo cambia un número, basta un parámetro | Si cada "caja" tuviera además un comportamiento visual realmente distinto, ahí sí convendría algo más flexible |
| 6 | `tr.sendMail(...)` se llama directo dentro de `CobroOrden.manejar`, acoplando el cobro de la orden al detalle de cómo se notifica | Aplicación/dominio | **Observer** | Mediator, con el que se suele confundir, coordina objetos que se comunican entre sí en ambos sentidos; aquí solo se necesita difundir un evento a varios interesados (correo al cliente, aviso al mecánico) que no se hablan entre ellos | Si solo existiera un único correo fijo, sin planes de agregar más canales, añadir Observer sería complejidad de más |

---

## 3. Misión 2 — Una petición, varios patrones

### 3.1 Lo que hace el código

Abrir una orden de servicio (`/nueva`) es, de los cuatro proyectos revisados, el flujo que más cerca está de un diseño correcto: sí pasa por una cadena de responsabilidad real antes de llegar a `CobroOrden`. Pero esa cadena tiene un eslabón con una puerta trasera, y dentro de `CobroOrden` se sigue mezclando cálculo de costo, cobro externo, tres escrituras sin transacción y notificación por correo — todo en un solo método.

### 3.2 Camino corregido a seguir

| Paso | Qué ocurre | Tipo de componente | Patrón que representa en ese momento |
|---|---|---|---|
| 1 | El empleado del taller elige tipo de servicio, mecánico asignado y método de pago en el formulario, y presiona "Abrir orden" | Vista / pantalla del cliente | Representación de la interfaz (fuera del alcance de esta tabla de backend) |
| 2 | El formulario se envía como `POST /nueva` hacia el servidor | Petición HTTP | — |
| 3 | La petición entra por el enrutador de Express, con la cadena de middleware registrada globalmente (no armada a mano por ruta) | Enrutador de entrada | **Front Controller** |
| 4 | Antes de llegar a la lógica de la orden se revisa, en orden: que la sesión sea válida (sin aceptar cookies fabricadas por el cliente), que el mecánico elegido esté disponible, y se registra el intento en bitácora | Middleware / filtros previos | **Chain of Responsibility** (`AuthHandler` corregido → `BitacoraHandler` → caso de uso) |
| 5 | Un controlador delgado recibe los datos ya validados y llama al caso de uso, sin decidir reglas de negocio por su cuenta | Controlador de la operación | Controlador de la operación (recibe la entrada, no decide el negocio) |
| 6 | Se invoca la operación `abrirOrden(cliente, auto, mecanico, tipo, pago)` | Capa de casos de uso | **Service Layer** |
| 7 | Dentro de esa operación se elige el algoritmo de costo según el tipo de servicio, y el algoritmo de cobro según el método de pago | Selector de algoritmo | **Strategy** |
| 8 | Antes de ejecutar el cobro, se revisa una clave que identifica esta operación en particular, para que un doble clic no genere una segunda orden | Verificación de operación repetida | **Idempotencia** |
| 9 | Se traduce la petición de cobro al formato que entiende la pasarela externa, y su respuesta a un formato interno común | Conector hacia el proveedor externo | **Adapter** |
| 10 | La pasarela procesa el cobro y responde con un código de resultado | Servicio externo | — |
| 11 | Si el cobro fue exitoso, se guardan la orden, el registro de refacción usada y la ocupación del mecánico como una sola operación conjunta, usando la conexión dedicada ya obtenida: o se guardan las tres cosas, o no se guarda ninguna | Persistencia de datos | **Repository + Unit of Work** |
| 12 | Una vez confirmada la orden, se avisa a quienes deben reaccionar (correo al cliente, aviso al mecánico asignado) sin que el caso de uso tenga que conocer a cada uno por nombre | Notificación de eventos internos | **Observer** |
| 13 | Si la pasarela tarda demasiado o falla de forma repetida, se deja de insistir tras un tiempo límite, sin bloquear el resto del sistema (el inventario, que no depende del banco, sigue funcionando) | Protección ante fallas del proveedor externo | **Timeout + Circuit Breaker** |
| 14 | Se arma la respuesta para el empleado confirmando la orden abierta, sin depender de un mensaje de "no recargue" como única medida de seguridad | Formato de salida | Plantilla de salida (adaptada al tipo de cliente que la pidió) |

---

## 4. Misión 3 — Políticas transversales

### a) Cuándo y por qué conviene una sola puerta de entrada (Front Controller)

En este proyecto la cadena de autenticación sí existe y está bien escrita, pero solo se activa para `/nueva`: `/`, `/login`, `/entrega` e `/inventario` quedan fuera. Conviene una sola puerta de entrada precisamente para que ninguna ruta quede "olvidada" fuera de la revisión — si la protección se arma a mano ruta por ruta, es cuestión de tiempo para que una quede sin proteger, como pasó con `/entrega` (que ni siquiera revisa sesión).

### b) Qué ya traen los marcos de trabajo modernos para esto

Express ya ofrece `app.use()` para registrar middleware una sola vez y que se aplique a todas las rutas (o a un prefijo de rutas) que se necesite, exactamente el mecanismo que reemplazaría instanciar la cadena a mano en cada ruta. También existe el paquete estándar `cookie-parser`, que reemplazaría el análisis manual de cookies del proyecto. La cadena de clases (`Handler.js`) en sí **no está de más** — es una implementación correcta de Chain of Responsibility — solo falta conectarla como middleware real en vez de instanciarla dentro de una sola ruta.

### c) Orden correcto de la revisión previa

1. *Autenticación* — confirmar quién es el empleado que hace la petición, sin aceptar cookies que el propio cliente pueda fabricar.
2. *Validación de negocio* — confirmar que el mecánico elegido esté disponible.
3. *Bitácora* — dejar constancia de que la petición ocurrió.
4. *Caso de uso* — ejecutar la apertura de la orden en sí.

Cobrar antes de autenticar es un error grave: si el cobro ocurre antes de confirmar la identidad de quien abre la orden, y esa confirmación falla después, no hay manera limpia de saber a quién pertenece ese dinero ni cómo revertirlo con seguridad.

### d) Qué NO debe ir dentro de esa cadena de filtros previos

No deben colocarse ahí las reglas específicas de la orden (costo según tipo de servicio, qué pasarela usar según el método de pago). Esas decisiones pertenecen al caso de uso concreto (`abrirOrden`) y deben vivir dentro de él, no en un filtro genérico que se ejecuta para todas las peticiones por igual.
