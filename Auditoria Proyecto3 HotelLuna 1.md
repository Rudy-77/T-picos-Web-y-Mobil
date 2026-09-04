# Auditoría de arquitectura — Hotel Luna (Spring Boot)

**Alumno:**
> **Pérez Martínez Paulo César**
---

Para cada archivo se buscó qué mala práctica aparece, indicando el archivo y la línea donde se observa.

---

## 1. General

### 1.1 Patrones de diseño

Este proyecto repite el patrón de los dos anteriores (un framework maduro presente, pero mal aprovechado), con una variante más grave: aquí el "intento casero" no está muerto, **sí está conectado** y compite con el mecanismo real del framework.

- `pom.xml:7` agrega la dependencia `spring-boot-starter-security`, pero en todo el proyecto no existe ninguna clase de configuración de seguridad (`SecurityConfig` o similar): la herramienta está instalada pero nunca configurada.
- En vez de usarla, el equipo escribió su propio servlet de entrada: `FrontControllerServlet.java`, anotado con `@WebServlet(urlPatterns="/*")` y activado por `@ServletComponentScan` en `HotelApp.java`. Esto significa que **sí está vivo** y compite directamente con el `DispatcherServlet` que Spring MVC ya usa para atender `/reservar` a través de `ReservaCtrl`. Hay, literalmente, dos puntos de entrada distintos peleando por la misma ruta.
- Ese servlet casero además tiene una lista `cadena` de `FiltroCasero` que **nunca se llena** en ningún lugar del código: el "Chain of Responsibility" que intenta construir nunca ejecuta ningún filtro real.

### 1.2 Malas prácticas detectadas

| Archivo / carpeta | Qué se observa | Por qué es un problema |
|---|---|---|
| `pom.xml:7` | Se agrega `spring-boot-starter-security` como dependencia | La librería de seguridad está instalada pero no configurada en ningún lado: no protege absolutamente nada tal como está. |
| `FrontControllerServlet.java:6-13` | Servlet propio mapeado a `/*` (todas las rutas), con una lista de filtros que nunca se llena, y que solo "atiende" `/reservar` escribiendo el texto literal `"despacho casero"` | Compite con el `DispatcherServlet` de Spring por la misma ruta que ya atiende `ReservaCtrl`; además, el `for` sobre `cadena` no filtra nada porque la lista siempre está vacía — es una cadena de responsabilidad de fachada, sin eslabones reales. |
| `HomeCtrl.java:15` | `if("admin_bypass".equals(c.getName())) { req.getSession().setAttribute("eid",1); ok=true; }` | La misma puerta trasera de los proyectos anteriores: cualquiera con esa cookie entra como el empleado 1 sin validar nada más. |
| `HomeCtrl.java:19` | Ciclo de 8 llamadas HTTP a `http://127.0.0.1/mod/i` con `catch(Exception e){}` vacío | Trabajo remoto repetido cuyo resultado se ignora si falla; oculta cualquier error real detrás de un `catch` silencioso, igual que en los dos proyectos anteriores. |
| `home.html:1` | `<div th:utext='${mods}'></div>` | `th:utext` inserta el contenido **sin escapar**; si alguno de esos 8 endpoints devolviera HTML/JS malicioso, se ejecutaría tal cual en la página del hotel. |
| `LoginCtrl.java:13` | `"SELECT id, rol FROM empleados WHERE correo='"+correo+"' AND clave='"+clave+"'"` armado por concatenación | Inyección SQL clásica: un correo especial puede alterar la consulta y entrar sin conocer la clave real. |
| `LoginCtrl.java:16-17` | Se guarda la sesión (`eid`) **y además** dos cookies (`luna_ok`, `admin_bypass` si el rol es `gerente`) | Dos mecanismos de identidad al mismo tiempo; la cookie la controla el navegador, no el servidor — es la fuente de la puerta trasera que explota `HomeCtrl`. |
| `FacturaSql.java:12` | Dentro del `for` que recorre reservas se hace una consulta nueva de `spa_cortesia` por cada huésped, armada por concatenación (`"...WHERE huesped='"+r.get("huesped")+"'"`) | Problema N+1 (una consulta extra por cada reserva) combinado con inyección SQL, porque el nombre del huésped viaja sin sanitizar. |
| `facturas.html:1` | `<div th:utext='${@facturaSql.tabla()}'></div>` | El HTML armado a mano en `FacturaSql.tabla()` se inserta sin escapar; si un huésped se registró con un nombre que incluya HTML, quedaría incrustado tal cual en la factura de cualquier otro. |
| `CheckinCtrl.java:12-13` | Dos `jdbc.update(...)` armados por concatenación de texto (aunque `reserva` ya llega tipado como `int` por Spring, y por eso el riesgo real de inyección aquí es bajo) sin usar parámetros de `JdbcTemplate`, y sin transacción entre ambas actualizaciones | Aun con bajo riesgo de inyección en este caso puntual, es el mismo hábito repetido de no usar consultas parametrizadas; y si el segundo `update` (la llave) falla, la reserva ya quedó marcada como `inhouse` sin llave asociada. |
| `ReservaCtrl.java:16-24` | `if/elif` de 5 casos para el precio según tipo de habitación, y otro `if/elif` de 4 casos que modifican ese precio según la tarifa (desayuno, todo incluido, corporativo, luna de miel) | Dos catálogos de reglas mezclados en cascada dentro del mismo método; agregar un tipo de habitación o una tarifa nueva obliga a tocar el mismo bloque cada vez. |
| `ReservaCtrl.java:34-36` | Se inserta la reserva, se marca una habitación como ocupada y se da de alta el spa de cortesía como tres sentencias sueltas, sin transacción | Si falla el segundo o tercer `update`, queda una reserva pagada sin habitación marcada o sin su spa de cortesía. |
| `ReservaCtrl.java:35` | `"UPDATE habitaciones SET ocupada=1 WHERE tipo='"+tipo+"' LIMIT 1"` sin ningún bloqueo de fila ni verificación de que la habitación elegida siga libre en ese instante | **Condición de carrera real**: si dos huéspedes reservan el mismo tipo de habitación casi al mismo tiempo, ambas peticiones pueden leer "hay una libre" antes de que la otra la marque, y terminar sobrevendiendo la misma habitación — esto no depende de que alguien ataque el sistema, pasa con uso normal y concurrente. |
| `ReservaCtrl.java:37-38` | `mail.send(msg)` se llama directo dentro de `alta()`, acoplando la reserva con el detalle de cómo se notifica | Si mañana se necesita también avisar a recepción o generar la factura automáticamente, hay que volver a tocar este mismo método. |
| `reservar.html:5` | Botón con el texto literal `"Reservar — no recargue"` como única defensa contra doble envío | No es un control real: un doble clic puede generar dos reservas y dos cobros para el mismo huésped. |
| `src/main/resources/static/css/ruido.css` | 90 clases (`mod_caja_0` a `mod_caja_89`) casi idénticas, cambiando solo el `padding` | El mismo archivo de código muerto que ya apareció en los dos proyectos anteriores. |
| `application.properties:2-3` | Usuario y contraseña de la base de datos en texto plano dentro del archivo de configuración | Mismo problema de credenciales sin externalizar de los proyectos anteriores. |
| `docs/README_ARQ.txt` y `docs/ER.txt` | Describen un sistema de **inventario de almacén tipo NASA** ("SKU de transbordador", "racks"), prohíben tocar las tablas reales (`huespedes`, `reservas`, `spa`), y afirman "Spring Security YA autentica" y "Unit of Work = `@Transactional` en todos los servicios (ya puesto)" | Documentación de un dominio de negocio completamente distinto (almacén), y además **falsa** sobre el propio código: no existe ningún `@Transactional` en el proyecto, y Spring Security no está configurado en ningún lado pese a lo que dice el documento. |
| `docs/README_ARQ.txt:3` | El documento dice explícitamente: "PROHIBIDO servlet FrontController propio" | Justo lo que el proyecto sí tiene (`FrontControllerServlet.java`, vivo y registrado): la documentación prohíbe exactamente la mala práctica que el código comete. |

### 1.3 ¿Se puede corregir poco a poco, o conviene rehacerlo desde cero?

**Se recomienda rehacer la arquitectura desde cero**, apoyándose en el código actual solo como referencia de las reglas de negocio (precios por tipo de habitación, modificadores de tarifa, qué pasa al hacer check-in), pero no como base para editar línea por línea.

Lo que sí se puede reutilizar: el modelo de datos base una vez depurado, las reglas de precio por tipo de habitación y tarifa, y el flujo general de "reservar → cobrar → asignar habitación → avisar".

---

## 2. Misión 1 — Dos puertas de entrada compitiendo por la misma ruta

| # | Problema detectado en el proyecto | Capa afectada | Patrón(es) que lo resuelve | Por qué ese y no el patrón parecido que suele confundirse | Cuándo NO conviene aplicarlo |
|---|---|---|---|---|---|
| 1 | `FrontControllerServlet` (mapeado a `/*`) compite con el `DispatcherServlet` de Spring por la ruta `/reservar`, y su lista de filtros (`FiltroCasero`) nunca se llena; además `spring-boot-starter-security` está instalado pero jamás configurado | Políticas transversales | **Front Controller** (usar solo el `DispatcherServlet` de Spring, eliminando el servlet casero) **+ Chain of Responsibility** (configurar la cadena de filtros de Spring Security, no `FiltroCasero`) | Decorator, con el que se suele confundir, siempre deja pasar la petición envolviéndola; la cadena necesita poder **detener** la petición si la sesión no es válida, y aquí ni siquiera hay una cadena real que ejecutar | Si el sitio tuviera 2-3 páginas públicas fijas sin planes de crecer, no se justifica el esfuerzo de centralizar |
| 2 | `ReservaCtrl.alta()` tiene un `if/elif` de 5 tipos de habitación para el precio base, y otro `if/elif` de 4 tarifas que modifican ese precio (suma, resta porcentual) en cascada | Aplicación/dominio | **Strategy** (elegir el precio base según tipo de habitación) **+ Decorator** (aplicar los modificadores de tarifa envolviendo el precio base, ya que son ajustes que se van sumando/aplicando sobre un valor, no algoritmos completos distintos entre sí) | Aplicar Strategy también a las tarifas obligaría a escribir una "estrategia" nueva por cada combinación de tipo+tarifa; Decorator es más preciso porque cada tarifa simplemente envuelve y ajusta el precio que ya calculó el Strategy de habitación | Si las tarifas nunca fueran a combinarse ni a crecer en variantes, un simple `if` bastaría sin necesidad de una capa extra |
| 3 | `FacturaSql.tabla()` ejecuta SQL crudo con una consulta N+1 dentro del ciclo, arma el HTML a mano, y `facturas.html` lo inserta sin escapar (`th:utext`) | Presentación + Datos | **Repository + Service Layer** | Facade, con el que se suele confundir, agrupa llamadas a un subsistema para simplificar su uso, pero no resuelve que la vista reciba HTML ya armado con SQL embebido; Repository es la pieza que aísla cómo se consultan los datos, dejando que Thymeleaf escape el resultado de forma normal | Si fuera una sola consulta simple, usada una única vez, no se justifica una capa de repositorio completa |
| 4 | `ReservaCtrl.alta()` inserta reserva, habitación y spa como tres pasos sueltos sin transacción, marca la habitación con un `UPDATE ... LIMIT 1` sin bloqueo (riesgo real de sobreventa con dos reservas simultáneas), y la única defensa contra doble envío es un texto de "no recargue" | Aplicación/dominio + Datos | **Idempotencia (clave de operación) + Unit of Work + bloqueo de fila** (`@Transactional` + `SELECT ... FOR UPDATE` o control optimista al asignar la habitación) | Arreglar solo la redacción del botón no evita ni el doble envío ni que dos peticiones concurrentes elijan la misma habitación libre al mismo tiempo; hace falta tanto una clave de operación como un bloqueo real sobre el recurso escaso (la habitación) | Si el hotel reservara por bloques garantizados (una habitación específica y no "cualquiera libre de ese tipo"), el riesgo de sobreventa desaparecería y bastaría con la idempotencia simple |
| 5 | `static/css/ruido.css` tiene 90 clases casi idénticas, cada una cambiando solo el `padding` | Presentación (frontend) | **Valor único parametrizado** (variable/mixin de espaciado, no un patrón GoF) | Strategy tiene sentido cuando el comportamiento cambia entre variantes; aquí solo cambia un número, basta un parámetro | Si cada "caja" tuviera además un comportamiento visual realmente distinto, ahí sí convendría algo más flexible |
| 6 | `mail.send(msg)` se llama directo dentro de `ReservaCtrl.alta()`, acoplando la reserva al detalle de cómo se notifica | Aplicación/dominio | **Observer** | Mediator, con el que se suele confundir, coordina objetos que se comunican entre sí en ambos sentidos; aquí solo se necesita difundir un evento a varios interesados (correo, recepción, facturación) que no se hablan entre ellos | Si solo existiera un único correo fijo, sin planes de agregar más canales, añadir Observer sería complejidad de más |

---

## 3. Misión 2 — Una petición, varios patrones

### 3.1 Lo que hace el código

Hacer una reserva (`/reservar`) pasa formalmente por `ReservaCtrl`, pero esa misma ruta también es "atendida" por el `FrontControllerServlet` casero que compite con Spring, y dentro del controlador real se mezclan: cálculo de precio en cascada, cobro con una pasarela externa, tres escrituras sin transacción (una de ellas con riesgo real de sobreventa), y el envío de un correo — todo sin ninguna revisión previa de sesión centralizada.

### 3.2 Camino corregido a seguir

| Paso | Qué ocurre | Tipo de componente | Patrón que representa en ese momento |
|---|---|---|---|
| 1 | El huésped elige tipo de habitación, tarifa y método de pago en el formulario, y presiona "Reservar" | Vista / pantalla del cliente | Representación de la interfaz (fuera del alcance de esta tabla de backend) |
| 2 | El formulario se envía como `POST /reservar` hacia el servidor | Petición HTTP | — |
| 3 | La petición entra únicamente por el `DispatcherServlet` de Spring (eliminando el `FrontControllerServlet` casero que compite por la misma ruta) | Enrutador de entrada | **Front Controller** |
| 4 | Antes de llegar a la lógica de reserva se revisa, en orden: que la sesión del empleado/huésped sea válida, que exista disponibilidad real del tipo de habitación, y se registra el intento en bitácora | Middleware / filtros previos | **Chain of Responsibility** (cadena de filtros de Spring Security, no `FiltroCasero`) |
| 5 | Un controlador delgado recibe los datos ya validados y llama al caso de uso, sin decidir reglas de negocio por su cuenta | Controlador de la operación | Controlador de la operación (recibe la entrada, no decide el negocio) |
| 6 | Se invoca la operación `reservarHabitacion(huesped, tipo, tarifa, pago)` | Capa de casos de uso | **Service Layer** |
| 7 | Dentro de esa operación se elige el precio base según el tipo de habitación, y luego se le aplican los modificadores de tarifa envolviendo ese precio | Selector de algoritmo + ajuste en cascada | **Strategy** (tipo de habitación) **+ Decorator** (modificadores de tarifa) |
| 8 | Antes de ejecutar el cobro, se revisa una clave que identifica esta operación en particular, para que un doble clic no genere una segunda reserva | Verificación de operación repetida | **Idempotencia** |
| 9 | Se traduce la petición de cobro al formato que entiende la pasarela externa, y su respuesta a un formato interno común | Conector hacia el proveedor externo | **Adapter** |
| 10 | La pasarela procesa el cobro y responde con un código de resultado | Servicio externo | — |
| 11 | Si el cobro fue exitoso, se reserva una habitación específica **con bloqueo** (para evitar que dos huéspedes se queden con la misma), se guarda la reserva y se da de alta el spa de cortesía como una sola operación conjunta: o se guardan las tres cosas, o no se guarda ninguna | Persistencia de datos | **Repository + Unit of Work** (`@Transactional` + bloqueo de fila al elegir la habitación) |
| 12 | Una vez confirmada la reserva, se avisa a quienes deben reaccionar (correo al huésped, aviso a recepción, alta en facturación) sin que la reserva tenga que conocer a cada uno por nombre | Notificación de eventos internos | **Observer** |
| 13 | Si la pasarela tarda demasiado o falla de forma repetida, se deja de insistir tras un tiempo límite, sin bloquear el resto del sistema (la disponibilidad de habitaciones, que no depende del banco, sigue funcionando) | Protección ante fallas del proveedor externo | **Timeout + Circuit Breaker** |
| 14 | Se arma la respuesta para el huésped confirmando la reserva y la habitación asignada, sin depender de un mensaje de "no recargue" como única medida de seguridad | Formato de salida | Plantilla de salida (adaptada al tipo de cliente que la pidió) |

---

## 4. Misión 3 — Políticas transversales

### a) Cuándo y por qué conviene una sola puerta de entrada (Front Controller)

En este proyecto el problema no es solo que la revisión de sesión se repita distinta en `HomeCtrl` y `LoginCtrl` (ambas aceptando la cookie `admin_bypass`): hay literalmente **dos puntos de entrada compitiendo** por la misma ruta (`FrontControllerServlet` y el `DispatcherServlet` de Spring). Conviene una sola puerta de entrada precisamente para evitar este tipo de ambigüedad: cuando dos mecanismos distintos pueden atender la misma petición, nadie puede predecir con certeza cuál la procesó ni bajo qué reglas.

### b) Qué ya traen los marcos de trabajo modernos para esto

Spring Boot ya trae Spring Security, un mecanismo de filtros probado y configurable declarativamente — y este proyecto **ya pagó el costo de incluirlo** en `pom.xml`, pero nunca lo configuró. En su lugar, se construyó desde cero un servlet y una interfaz de filtros propios (`FiltroCasero`) que ni siquiera llegan a ejecutar un solo filtro real. El esfuerzo de "hacerlo a mano" se gastó dos veces: una vez de más (la dependencia sin usar) y otra de menos (la solución casera, incompleta).

### c) Orden correcto de la revisión previa

1. *Autenticación* — confirmar quién es el empleado o huésped que hace la petición.
2. *Validación de negocio* — confirmar que realmente existe una habitación disponible del tipo solicitado, idealmente con un bloqueo que impida que otra reserva tome la misma habitación mientras se procesa esta.
3. *Bitácora* — dejar constancia de que la petición ocurrió.
4. *Caso de uso* — ejecutar la reserva en sí.

Cobrar antes de confirmar disponibilidad real es un error grave: si se cobra primero y luego resulta que la habitación ya no estaba disponible (por la condición de carrera de `ReservaCtrl.java:35`), hay que devolver un cobro ya hecho en vez de simplemente no haberlo procesado.

### d) Qué NO debe ir dentro de esa cadena de filtros previos

No deben colocarse ahí las reglas específicas de precio (tipo de habitación, modificadores de tarifa) ni la elección del método de pago. Esas decisiones pertenecen al caso de uso concreto (`reservarHabitacion`) y deben vivir dentro de él, no en un filtro genérico que se ejecuta para todas las peticiones por igual.
