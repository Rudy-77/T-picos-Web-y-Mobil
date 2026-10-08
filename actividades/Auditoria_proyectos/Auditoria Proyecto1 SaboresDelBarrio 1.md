# Auditoría de arquitectura — Sabores del Barrio (Laravel)

**Alumnos:**
> **Pérez Martínez Paulo César**
> **Martinez Enrique**
---

Para cada archivo se buscó qué mala práctica aparece, indicando el archivo y la línea donde se observa.

---

## 1. General

### 1.1 Patrones de diseño

El proyecto sí usa Laravel (un framework con MVC, enrutador y sistema de middleware ya construidos), pero el equipo lo usa de forma parcial e inconsistente: en algunas rutas se respeta el flujo normal de Laravel (controlador → vista), y en otras se rompe ese flujo por completo insertando SQL crudo dentro de las vistas Blade.

- Existe una clase `FrontController` (`app/Http/Controllers/FrontController.php`) que reimplementa manualmente un enrutador con su propio método `dispatch()`, pero **no está conectada a nada**: `routes/web.php` nunca la usa. Es un intento de patrón Front Controller que ignora que Laravel ya es, en sí mismo, un Front Controller.
- Existen dos middlewares (`Authenticate.php`, `SoloRepartidor.php`) registrados como alias en `Kernel.php`, pero **ninguna ruta en `routes/web.php` los utiliza**. Es la misma historia que la contraseña "externalizada" del caso anterior: la pieza correcta existe, pero no se usa donde debería.
- No hay Repository ni capa de datos: los controladores (y hasta las vistas) llaman directo a `DB::select(...)` o a `mysqli_query(...)` con SQL armado por concatenación.

El proyecto no sigue un único mecanismo de autenticación (mezcla cookies y sesión), no separa consistentemente la vista de la consulta a base de datos, y tiene rutas duplicadas para la misma función (`/menu` y `/menu_old`).

### 1.2 Malas prácticas detectadas

| Archivo / carpeta | Qué se observa | Por qué es un problema |
|---|---|---|
| `LoginController.php:9` | `"SELECT id, rol, nombre FROM usuarios WHERE correo='$u' AND pass='$p'"` armada por concatenación directa | Inyección SQL: un correo especial puede alterar el significado de la consulta y entrar sin conocer la contraseña real. |
| `LoginController.php:9` | La contraseña se compara tal cual está en la tabla, sin cifrado | Si se copia la base de datos, todas las contraseñas quedan expuestas en texto legible. |
| `LoginController.php:13-14` | Se guarda la sesión (`$_SESSION`/session Laravel) **y además** dos cookies (`logueado`, `admin_bypass`) para recordar quién inició sesión | Dos mecanismos de identidad al mismo tiempo; la cookie `admin_bypass` la controla el navegador del usuario, no el servidor. |
| `HomeController.php:8` | `if ($r->cookie('admin_bypass')) $r->session()->put('uid', 1);` | Puerta trasera: basta con tener esa cookie (la que el propio login regala a cualquier admin) para entrar como el usuario 1 sin validar nada más. |
| `HomeController.php:15` | Dentro del `foreach` de restaurantes se ejecuta una consulta `COUNT(*)` nueva por cada restaurante | Problema N+1: si hay 50 restaurantes, son 50 consultas para armar una sola página. |
| `HomeController.php:16` y `:19` | Se hacen llamadas HTTP (`file_get_contents`) a `promo.php` por cada restaurante y en un ciclo fijo de 8 a `api.php?bloque=` | Trabajo remoto repetido que ni siquiera se usa de forma visible en la vista; ralentiza la página sin necesidad, similar al ciclo `md5` inútil del caso anterior. |
| `MenuController.php:9-14` (`verViejo`, ruta `/menu_old`) | Segunda versión del menú que arma SQL con `$rid` sin sanitizar y hace `echo` directo del HTML desde el controlador | Duplicado de `ver()`, con inyección SQL y sin pasar por ninguna vista; nadie indica cuál versión es la vigente. |
| `resources/views/menu.blade.php:3-14` | Conexión `mysqli_connect` directa dentro de la vista, SQL armado con `$_GET['rid']` sin sanitizar, y campos ocultos armados directo desde `$_GET['u']`/`$_GET['m']` sin escapar | Mezcla total de presentación y datos, inyección SQL, y los campos ocultos pueden inyectar HTML/JS (XSS) porque no pasan por Blade (`{{ }}`) sino por `echo` crudo. |
| `resources/views/reporte.blade.php:3-9` | Misma conexión `mysqli` cruda, y una consulta de nombre de usuario **por cada fila** dentro del `while` | Vista con SQL embebido (otra vez el problema N+1) en vez de recibir los datos ya armados desde el controlador. |
| `resources/views/resenas.blade.php:2-5` | Igual: `mysqli_connect` en la vista, `$_GET['rid']` concatenado directo al SQL | Inyección SQL en una tercera vista distinta; el patrón se repite en vez de corregirse una sola vez. |
| `ResenaController.php:10` | `INSERT INTO resenas (...) VALUES (".$r->rid.", ".$r->uid.", '".$r->texto."', ".$r->estrellas.")"` | El `uid` y las `estrellas` los manda el propio formulario sin validar ni comprobar sesión: cualquiera puede publicar una reseña "de parte" de otro usuario. |
| `PedidoController.php:17-22` | `if/elseif` de 5 casos casi idénticos para el costo de envío (`moto`, `bici`, `dron`, `caminando`, `uber_falso`) | Agregar un nuevo tipo de envío obliga a tocar este mismo bloque y arriesga romper los demás casos. |
| `PedidoController.php:24-41` | `if/elseif` de 5 métodos de pago, cada uno con su propia lógica (incluida una llamada `curl` directa a una pasarela externa) mezclada dentro del mismo método | Igual que el `switch` de bancos del caso anterior: agregar un método de pago nuevo es copiar y pegar un bloque completo dentro del controlador. |
| `PedidoController.php:43-49` | Se inserta el pedido, luego el detalle (en un ciclo) y luego la cola de reparto como tres pasos sueltos, sin transacción | Si falla el segundo o tercer paso, queda un pedido "pagado" sin detalle o sin entrar a la cola de reparto: datos a medias. |
| `PedidoController.php:50` | `echo "<script>alert('listo, no recargue'); location='/';</script>";` como única protección contra doble envío | No es un control real: solo le pide al usuario, por un mensaje, que no le dé doble clic. Un doble envío genera un doble cobro real. |
| `RepartoController.php:7` | `if (!$r->session()->get('uid') && !$r->cookie('admin_bypass')) abort(403);` | Vuelve a aceptar la cookie `admin_bypass` como entrada válida, ignorando los middlewares `auth`/`repartidor` que ya existen en el proyecto pero nunca se asignaron a esta ruta. |
| `RepartoController.php:13-16` | Tres actualizaciones SQL sueltas (`cola_reparto`, `pedidos`, `puntos`) con `$id` tomado directo del request, sin transacción | Inyección SQL adicional, y si falla a la mitad, la cola queda "entregada" pero el pedido no, o viceversa. |
| `app/Http/Kernel.php` + `routes/web.php` | Los middlewares `auth` y `repartidor` están definidos pero **ninguna ruta los usa** | Exactamente el mismo patrón del caso anterior: la protección "ya existe" en el código pero nunca se activa donde hace falta. |
| `app/Http/Controllers/FrontController.php` | Clase completa de enrutamiento manual que no está referenciada en ningún lado del proyecto | Código muerto que además compite conceptualmente con el enrutador nativo de Laravel; confunde a quien llega nuevo al proyecto pensando que ahí está la lógica real de entrada. |
| `public/css/ruido.css` | 90 clases (`mod_caja_0` a `mod_caja_89`) casi idénticas, cada una cambiando solo el valor de `padding` | Código muerto que infla el archivo; debería ser una sola clase con un valor variable (o una utilidad de espaciado), no 90 copias. |
| `.env:3` y dentro de `menu.blade.php:3`, `reporte.blade.php:3`, `resenas.blade.php:2` | La contraseña de la base de datos ya está bien externalizada en `.env`, pero igual aparece **hardcodeada de nuevo** dentro de tres vistas distintas vía `mysqli_connect('127.0.0.1','root','password',...)` | El equipo sí tenía la herramienta correcta (variables de entorno) pero la vista la ignora por completo y repite la contraseña en texto plano en tres lugares más. |
| `documentacion/LEAME_ARQUITECTO.txt` y `documentacion/diagrama_bd.txt` | Describen un sistema completamente distinto: "Sistema de Nómina Ganadera", tablas `Rancho_V2`, `Traslado_Ganado`, login solo contra ganado, y afirman que "prevalece este documento" sobre el código | La documentación no solo está desactualizada, describe un dominio de negocio totalmente diferente (censo de ganado) al que realmente implementa el código (pedidos de comida). Si alguien confía en el documento, no va a entender nada del sistema real. |

### 1.3 ¿Se puede corregir poco a poco, o conviene rehacerlo desde cero?

**Se recomienda rehacer la arquitectura desde cero**, apoyándose en el código actual solo como referencia de las reglas de negocio (cómo se arma un pedido, cómo se calcula el costo de envío, qué pasa cuando se marca "entregado"), pero no como base para editar línea por línea.

Lo que sí se puede reutilizar: el modelo de datos base una vez depurado, las reglas de costo de envío y de acumulación de puntos, y el flujo general de "elegir platillos → cobrar → encolar reparto → avisar".

---

## 2. Misión 1 — Un framework MVC no es, por sí solo, una arquitectura

| # | Problema detectado en el proyecto | Capa afectada | Patrón(es) que lo resuelve | Por qué ese y no el patrón parecido que suele confundirse | Cuándo NO conviene aplicarlo |
|---|---|---|---|---|---|
| 1 | Existe un `FrontController` manual sin usar, y la autenticación se revisa distinto en `HomeController` (acepta cookie `admin_bypass`), en `RepartoController` (sesión O esa misma cookie) y en `MenuController`/`ResenaController` (no revisan nada) | Políticas transversales | **Front Controller** (el nativo de Laravel, eliminando el manual) **+ Chain of Responsibility** (activar los middlewares `auth`/`repartidor` que ya existen) | Decorator, con el que se suele confundir, siempre deja pasar la petición envolviéndola; la cadena de middleware necesita poder **detenerla** si la sesión no es válida | Si la app tuviera 2-3 rutas públicas fijas sin planes de crecer, no se justifica el esfuerzo de centralizar |
| 2 | `PedidoController` tiene un `if/elseif` de 5 métodos de pago, cada uno con su propia lógica y, en el caso de tarjeta, una llamada `curl` directa a una pasarela externa embebida ahí mismo | Aplicación/dominio + Integración | **Strategy** (elegir el algoritmo de cobro) **+ Adapter** (traducir la petición/respuesta de la pasarela a un formato interno común) | Factory, que suele confundirse aquí, sirve para decidir qué objeto crear; aquí el cliente ya eligió el método de pago en el formulario, lo que cambia es el algoritmo de cobro, no el tipo de objeto | Si solo existiera un método de pago sin planes de agregar otro, una interfaz con una sola implementación sería complejidad de más |
| 3 | `menu.blade.php`, `reporte.blade.php` y `resenas.blade.php` abren su propia conexión `mysqli` y ejecutan SQL directo dentro de la vista, ignorando por completo `DB::` de Laravel | Presentación + Datos | **Repository + Service Layer** | Facade, con el que se suele confundir, agrupa llamadas a un subsistema para simplificar su uso, pero no resuelve el problema de fondo: la vista contiene SQL mezclado con HTML. Repository es la pieza exacta que aísla cómo se consultan los datos | Si fuera una sola consulta simple usada una única vez, sin repetirse en otra vista, no se justifica una capa de repositorio completa |
| 4 | `PedidoController::guardar` inserta pedido, detalle y cola de reparto como pasos sueltos sin transacción, y la única defensa contra doble envío es un `alert()` pidiendo "no recargue" | Aplicación/dominio + Datos | **Idempotencia (clave de operación) + Unit of Work** | Arreglar solo el mensaje al usuario no evita que la misma petición HTTP se ejecute dos veces si hay doble clic o reintento de red | Si el pago fuera un único paso completamente síncrono y el banco garantizara que un mismo folio nunca se cobra dos veces, esta capa sería innecesaria |
| 5 | `public/css/ruido.css` tiene 90 clases casi idénticas, cada una cambiando solo el valor de `padding` | Presentación (frontend) | **Valor único parametrizado** (variable/mixin de espaciado, no un patrón GoF) | Strategy tiene sentido cuando el comportamiento cambia entre variantes; aquí el comportamiento es exactamente el mismo, solo cambia un número — basta un parámetro o variable CSS | Si cada "caja" tuviera además un comportamiento visual realmente distinto (no solo el padding), ahí sí convendría una solución más flexible tipo Strategy visual |
| 6 | `mail()` se llama directo dentro de `PedidoController::guardar` y de `RepartoController::cerrar`, acoplando el caso de uso al detalle de cómo se notifica | Aplicación/dominio | **Observer** | Mediator, con el que se suele confundir, coordina objetos que se comunican **entre sí** en ambos sentidos; aquí solo se necesita difundir un evento hacia varios interesados que no se hablan entre ellos, lo cual es exactamente el rol de Observer | Si solo existiera un único correo fijo, sin planes de agregar más suscriptores (SMS, notificación push, etc.), añadir Observer sería complejidad de más |

---

## 3. Misión 2 — Una petición, varios patrones

### 3.1 Lo que hace el código

El flujo de "hacer un pedido" (`/pedir`) sí pasa por un controlador dedicado (`PedidoController::guardar`), pero mezcla dentro de un solo método: cálculo de costos, selección de método de pago, llamada a una pasarela externa, tres escrituras a base de datos sin transacción, y el envío de un correo — todo sin ninguna revisión previa de sesión ni protección contra reenvíos.

### 3.2 Camino corregido a seguir

| Paso | Qué ocurre | Tipo de componente | Patrón que representa en ese momento |
|---|---|---|---|
| 1 | El cliente elige platillos, tipo de envío y método de pago en el menú, y presiona "Pedir" | Vista / pantalla del cliente | Representación de la interfaz (fuera del alcance de esta tabla de backend) |
| 2 | El formulario se envía como `POST /pedir` hacia el servidor | Petición HTTP | — |
| 3 | La petición entra por el enrutador nativo de Laravel (eliminando el `FrontController` manual sin usar) | Enrutador de entrada | **Front Controller** |
| 4 | Antes de llegar a la lógica de pedido se revisa, en orden: que la sesión sea válida, que el cliente que aparece en el formulario sea el mismo que inició sesión, que el restaurante/platillos sigan activos, y se registra el intento en bitácora | Middleware / filtros previos | **Chain of Responsibility** |
| 5 | Un controlador recibe los datos ya validados y llama al caso de uso, sin decidir reglas de negocio por su cuenta | Controlador de la operación | Controlador de la operación (recibe la entrada, no decide el negocio) |
| 6 | Se invoca la operación `pedirComida(clienteId, items, envio, pago)` | Capa de casos de uso | **Service Layer** |
| 7 | Dentro de esa operación se elige el algoritmo de costo de envío y el algoritmo de cobro según lo que mandó el formulario | Selector de algoritmo | **Strategy** |
| 8 | Antes de ejecutar el cobro, se revisa una clave que identifica esta operación en particular, para que un doble clic o un reenvío no genere un segundo pedido | Verificación de operación repetida | **Idempotencia** |
| 9 | Se traduce la petición de cobro al formato que entiende la pasarela externa, y su respuesta a un formato interno común | Conector hacia el proveedor externo | **Adapter** |
| 10 | La pasarela procesa el cobro y responde con un código de resultado | Servicio externo | — |
| 11 | Si el cobro fue exitoso, se guardan el pedido, su detalle y la entrada a la cola de reparto como una sola operación conjunta: o se guardan las tres cosas, o no se guarda ninguna | Persistencia de datos | **Repository + Unit of Work** |
| 12 | Una vez confirmado el pedido, se avisa a quienes deben reaccionar (correo al cliente, alta en la cola de reparto, aviso a caja), sin que la operación de pedido tenga que conocer a cada uno por nombre | Notificación de eventos internos | **Observer** |
| 13 | Si la pasarela tarda demasiado o falla de forma repetida, se deja de insistir después de un tiempo límite, sin bloquear el resto del sistema (el menú y las reseñas, que no dependen del banco, siguen funcionando) | Protección ante fallas del proveedor externo | **Timeout + Circuit Breaker** |
| 14 | Se arma la respuesta para el cliente confirmando el pedido y su folio, sin exponer el mensaje de "no recargue" como única medida de seguridad | Formato de salida | Plantilla de salida (adaptada al tipo de cliente que la pidió) |

---

## 4. Misión 3 — Políticas transversales

### a) Cuándo y por qué conviene una sola puerta de entrada (Front Controller)

En el proyecto actual, la revisión de sesión aparece distinta en `HomeController` (acepta la cookie de puerta trasera `admin_bypass`), en `RepartoController` (revisa sesión O esa misma cookie) y en `MenuController`/`ResenaController` (no revisa nada). Cuando la misma tarea — revisar quién es el usuario y si tiene permiso — se repite copiada en cada controlador, tarde o temprano una copia queda mal hecha o incompleta, como pasó aquí. Conviene una sola puerta de entrada cuando varias rutas necesitan pasar por las mismas revisiones antes de ejecutarse.

### b) Qué ya traen los marcos de trabajo modernos para esto

Laravel ya incluye el mecanismo de middleware, y en este proyecto **ya existen** dos middlewares escritos (`Authenticate.php`, `SoloRepartidor.php`) registrados como alias en `Kernel.php`. El problema no es la falta de la herramienta, sino que `routes/web.php` nunca los asigna a ninguna ruta — la solución ya estaba construida y quedó sin conectar.

### c) Orden correcto de la revisión previa

1. *Autenticación* — confirmar quién hace la petición.
2. *Validación de negocio* — confirmar que el restaurante/platillos siguen activos y que el `id_cliente` del formulario corresponde a la sesión activa (hoy `PedidoController` confía ciegamente en un campo oculto `id_cliente`, así que cualquiera puede pedir "a nombre de" otro usuario con solo cambiar ese campo).
3. *Bitácora* — dejar constancia de que la petición ocurrió.
4. *Caso de uso* — ejecutar el pedido en sí.

Cobrar antes de autenticar es un error grave: si el cobro ocurre antes de confirmar quién es el cliente, y esa confirmación falla después, no hay una manera limpia de saber a quién pertenece ese dinero ni cómo revertirlo con seguridad.

### d) Qué NO debe ir dentro de esa cadena de filtros previos

No deben colocarse ahí las decisiones específicas del pedido (qué método de envío eligió, cuánto cuesta cada platillo, qué pasarela usar). Esas reglas pertenecen al caso de uso concreto (`pedirComida`) y deben vivir dentro de él, no en un filtro genérico que se ejecuta para todas las peticiones por igual.
