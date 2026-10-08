# Auditoría de arquitectura — PasoFit (Flutter)

**Alumnos:**
> **Pérez Martínez Paulo César**
> **Martinez Enrique**
---

Para cada archivo se buscó qué mala práctica aparece, indicando el archivo y la línea donde se observa.

---

## 1. General

### 1.1 Patrones de diseño

Este proyecto no tiene backend propio en el repositorio (solo llama a endpoints externos), así que las malas prácticas se concentran en cómo se maneja el estado dentro de la app y cómo se accede a la base de datos local (`sqflite`).

- `pubspec.yaml:6-7` incluye **al mismo tiempo** `flutter_bloc` y `provider`, dos soluciones de manejo de estado distintas, cuando la propia documentación del proyecto dice explícitamente que Provider está "por si BLoC falla" y que **no hay que usar los dos**.
- Existe un `RelojCubit` (`lib/estado/reloj_cubit.dart`) construido correctamente sobre `flutter_bloc`, pero **no lo usa nadie**: la pantalla de cronómetro (`cronometro.dart`) en su lugar se suscribe a un `RelojBus` hecho a mano con una lista estática de funciones — es el mismo patrón de "la pieza correcta existe, pero el código usa la casera" que ya vimos en los proyectos con Front Controller y middleware sin conectar.
- La documentación (`docs/ARQUITECTURA.md:3,5`) da consejos técnicos correctos ("`flutter_bloc` YA es el Observer, prohibido listas de oyentes en el widget"; "el SQL vive en el repositorio, nunca en `State`"), pero el código hace exactamente lo contrario en ambos casos.

### 1.2 Malas prácticas detectadas

| Archivo / carpeta | Qué se observa | Por qué es un problema |
|---|---|---|
| `lib/estado/oyentes.dart:1-7` | `RelojBus` y `PesoBus`: listas estáticas de funciones (`List<void Function(...)>`) a las que cualquier pantalla se suscribe agregando un callback | Es un Observer hecho a mano con una lista global, justo lo que la documentación del propio proyecto prohíbe explícitamente ("prohibido listas de oyentes"), y existiendo ya `flutter_bloc` (que resuelve esto con streams) como dependencia. |
| `cronometro.dart:14` y `peso.dart:13` | `RelojBus.ticks.add(...)` / `PesoBus.kilos.add(...)` dentro de `initState()`, sin ningún `dispose()` que los remueva de la lista | **Fuga de memoria real**: cada vez que el usuario entra a Cronómetro o a Peso se agrega un nuevo listener a una lista que nunca se vacía; los widgets viejos (ya destruidos) siguen recibiendo eventos y llamando `setState()` sobre un `State` que ya no existe. |
| `lib/estado/reloj_cubit.dart` | Clase `RelojCubit` completa y correctamente escrita sobre `flutter_bloc`, pero nunca importada ni usada en ninguna pantalla | Código muerto: la solución correcta para el mismo problema que resuelve (mal) `RelojBus` existe en el repositorio, pero nadie la conecta. |
| `inicio.dart:16-18` | `if (a?['cookie'] != 'si' && a?['admin_bypass'] != '1') { // a veces entra igual }` — el cuerpo del `if` está **vacío** | Este es el caso más extremo de "revisión de acceso" de los cinco proyectos: no hay puerta trasera con cookie falsa porque **no hay ninguna revisión real** — el comentario del propio equipo ("a veces entra igual") documenta que la condición no bloquea nada, pase lo que pase. |
| `inicio.dart:20-22` | Ciclo de 8 llamadas HTTP a `http://127.0.0.1/fit/mod/$i` con `catch (_) {}` vacío | El mismo patrón de trabajo remoto repetido e ignorado que aparece en los cuatro proyectos anteriores. |
| `login.dart:13-14` | `if (r.body.contains('ok') || r.body.contains('id'))` decide si el login fue exitoso, y siempre navega con `arguments: {'uid': '1', ...}` sin importar qué usuario inició sesión | Doble problema: (1) buscar las palabras `'ok'`/`'id'` en cualquier parte del cuerpo de la respuesta es una validación frágil (una página de error que mencione un "id" también pasaría), y (2) el `uid` que se propaga a partir de ahí está **fijo en `'1'`**, así que cualquier persona que inicie sesión exitosamente queda identificada como el mismo usuario. |
| `logros.dart:18-20` | Dentro del `for` que recorre `logros_pend` se ejecuta una consulta nueva de `sesiones` por cada logro pendiente, con el tipo interpolado directo en el texto (`WHERE tipo='${r['tipo']}'`) | Problema N+1 (una consulta extra por logro) además del hábito de interpolar valores directo en el SQL en vez de usar los parámetros que `sqflite` ya ofrece en `rawQuery`. |
| `peso.dart:19-20` | `guardar()` no recibe ningún valor de peso capturado del usuario (no hay campo de entrada en la pantalla); en su lugar calcula el nuevo registro como el anterior **menos 0.2 siempre** (`k = ...- 0.2`), y lo inserta con el valor interpolado directo en el SQL | La app fabrica una "pérdida de peso" automática de 0.2 kg cada vez que se presiona el botón, sin que el usuario haya reportado nada real — no es un problema de seguridad, es un dato de negocio falso mostrado como si fuera una medición real. |
| `rutina.dart:12-16` | `if/elif` de 5 casos casi idénticos para las calorías según tipo de rutina (`cardio`, `fuerza`, `yoga`, `hiit`, `bailar`) | Agregar un tipo de rutina nuevo obliga a tocar este mismo bloque. |
| `rutina.dart:19-20` | Dos `INSERT` con el tipo de rutina y las calorías interpolados directo en el texto del SQL, sin usar los parámetros de `sqflite` | Mismo hábito de construir SQL por interpolación de texto en vez de parámetros, esta vez en dos tablas relacionadas (`sesiones` y `logros_pend`). |
| `rutina.dart:19-21` | Se insertan `sesiones` y `logros_pend`, y **después** se hace una llamada HTTP de notificación, todo sin transacción (`sqflite` ofrece `db.transaction()`, sin usar) | Si la segunda inserción falla, queda una sesión de entrenamiento registrada sin su logro pendiente asociado. |
| `rutina.dart:22` | `setState(() => txt = 'guardado $kcal — no recargue')` como única defensa contra doble envío | El mismo texto y el mismo problema de los cuatro proyectos anteriores: no es un control real contra un doble toque del botón. |
| `rutina.dart:21` | `http.post(...)` de notificación llamado directo dentro de `arrancar()`, acoplando el registro de la sesión al aviso por correo | Si mañana se necesita también actualizar un contador de racha o notificar por push, hay que volver a tocar este mismo método. |
| `rutina_old.dart` | Widget completo (`RutinaOld`) que solo muestra el texto "usar rutina.dart" | Archivo duplicado y en desuso que nadie limpió, el mismo hábito de dejar versiones viejas "por si acaso" que ya apareció en `app.old.js` del proyecto anterior. |
| `docs/ARQUITECTURA.md` | Describe una app de **banca móvil corporativa** ("token de firmas de un banco", pantallas de "transferir, saldos, tokens"), y afirma "no hay rutinas" | Documentación de un dominio de negocio completamente distinto (banca) al real (entrenamiento físico) — el mismo problema de los cuatro proyectos anteriores. A diferencia de ellos, aquí el documento sí da dos consejos técnicos correctos sobre BLoC y SQL, y el código los ignora ambos por completo. |

### 1.3 ¿Se puede corregir poco a poco, o conviene rehacerlo desde cero?

**Se recomienda rehacer la arquitectura desde cero**, apoyándose en el código actual solo como referencia de las reglas de negocio (calorías por tipo de rutina, qué logros se desbloquean), pero no como base para editar línea por línea. A diferencia de los demás proyectos, aquí sí hay una pieza ya construida y lista para reutilizar de verdad: `RelojCubit`, que solo necesita conectarse en vez de descartarse.

Lo que sí se puede reutilizar: el modelo de datos base una vez depurado, las reglas de calorías por tipo de rutina, y el flujo general de "iniciar rutina → calcular calorías → registrar sesión → avisar".

---

## 2. Misión 1 — Cuando la lista de oyentes está prohibida y aun así se usa

| # | Problema detectado en el proyecto | Capa afectada | Patrón(es) que lo resuelve | Por qué ese y no el patrón parecido que suele confundirse | Cuándo NO conviene aplicarlo |
|---|---|---|---|---|---|
| 1 | `RelojBus`/`PesoBus` son listas estáticas de funciones sin desuscripción, mientras que `flutter_bloc` ya está instalado y hasta existe un `RelojCubit` sin usar | Manejo de estado | **Observer** implementado con `Cubit`/`Bloc` (streams que Flutter cierra automáticamente al hacer `dispose()` del `BlocProvider`), no con listas estáticas propias | Podría pensarse que basta con convertir `RelojBus` en un **Singleton** más formal, pero el problema real no es la unicidad de la instancia — es la falta de un mecanismo de desuscripción, que es justo lo que un `Stream`/`Cubit` resuelve solo al cerrarse | Si un evento solo necesita viajar de un widget hijo a su padre inmediato, un callback simple es más sencillo que montar un Observer completo |
| 2 | `inicio.dart:16-18` tiene un `if` de revisión de acceso con el cuerpo vacío (no bloquea nada realmente), y ninguna otra pantalla revisa sesión de forma centralizada | Navegación / políticas transversales | **Front Controller** (un `onGenerateRoute` central que decida qué pantalla construir) **+ Chain of Responsibility** (una cadena de guardas de ruta antes de construir cualquier pantalla protegida) | Decorator, con el que se suele confundir, siempre deja pasar la construcción del widget envolviéndolo; la cadena de guardas necesita poder **impedir** la navegación si la sesión no es válida | Si la app tuviera una sola pantalla protegida y ninguna posibilidad de crecer, revisar la sesión ahí mismo sería suficiente |
| 3 | `rutina.dart` tiene un `if/elif` de 5 casos casi idénticos para las calorías según el tipo de rutina | Aplicación/dominio | **Strategy** | Factory, con el que se suele confundir, sirve para decidir qué objeto crear; aquí el usuario ya eligió el tipo de rutina en el `DropdownButton`, lo que cambia es el algoritmo de cálculo de calorías | Si solo existiera un tipo de rutina, sin planes de agregar más, esta capa sería complejidad de más |
| 4 | El SQL vive directo dentro de los `State` de las pantallas (`_L` en `logros.dart` con una consulta N+1, `_P` en `peso.dart`, `_R` en `rutina.dart`), justo lo contrario de lo que pide la propia documentación del proyecto | Presentación + Datos | **Repository + Service Layer** | Facade, con el que se suele confundir, agrupa llamadas a un subsistema para simplificar su uso, pero no resuelve que la pantalla contenga SQL mezclado con la interfaz; Repository es la pieza que aísla cómo se consultan los datos, y de paso resuelve el problema N+1 al traer todo en una sola consulta | Si fuera una sola consulta simple, usada una única vez, no se justifica una capa de repositorio completa |
| 5 | `rutina.dart` inserta sesión y logro pendiente sin transacción (`sqflite` ya ofrece `db.transaction()`), y la única defensa contra doble envío es el texto "no recargue" | Aplicación/dominio + Datos | **Idempotencia (clave de operación) + Unit of Work** (`db.transaction()`) | Arreglar solo el texto del botón no evita que un doble toque registre dos veces la misma sesión de entrenamiento | Si ambas inserciones fueran completamente independientes entre sí, envolverlas en una transacción sería innecesario |
| 6 | La llamada HTTP de notificación (`/fit/mail`) está pegada dentro de `arrancar()`, acoplando el registro de la sesión al aviso | Aplicación/dominio | **Observer** | Mediator, con el que se suele confundir, coordina objetos que se comunican entre sí en ambos sentidos; aquí solo se necesita difundir un evento (sesión registrada) a varios interesados (correo, contador de logros) que no se hablan entre ellos | Si solo existiera ese único aviso, sin planes de agregar más reacciones, añadir Observer sería complejidad de más |

---

## 3. Misión 2 — Una acción, varios patrones

### 3.1 Lo que hace el código

Iniciar una rutina (`arrancar()` en `RutinaPantalla`) mezcla en un solo método: cálculo de calorías, dos inserciones a SQLite sin transacción, una llamada de notificación externa y el mensaje de confirmación — todo sin haber revisado antes si existe una sesión válida (recordemos que esa revisión, en `inicio.dart`, no hace nada).

### 3.2 Camino corregido a seguir

| Paso | Qué ocurre | Tipo de componente | Patrón que representa en ese momento |
|---|---|---|---|
| 1 | El usuario elige el tipo de rutina en el menú desplegable y presiona "Iniciar" | Vista / pantalla del cliente | Representación de la interfaz (fuera del alcance de esta tabla de backend) |
| 2 | Se dispara la acción sobre el estado de la pantalla | Evento de interfaz | — |
| 3 | La navegación pasa por un enrutador central (`onGenerateRoute`) en vez de construir la pantalla directamente | Enrutador de entrada | **Front Controller** |
| 4 | Antes de permitir iniciar la rutina se revisa, en orden: que exista una sesión válida (corrigiendo el `if` vacío), que no haya ya una rutina en curso, y se registra el intento en bitácora | Guardas de navegación | **Chain of Responsibility** |
| 5 | Una pantalla delgada recibe el tipo de rutina ya validado y llama al caso de uso, sin decidir reglas de negocio por su cuenta | Controlador de la operación | Controlador de la operación (recibe la entrada, no decide el negocio) |
| 6 | Se invoca la operación `iniciarRutina(tipo)` | Capa de casos de uso | **Service Layer** |
| 7 | Dentro de esa operación se elige el algoritmo de cálculo de calorías según el tipo de rutina | Selector de algoritmo | **Strategy** |
| 8 | Antes de guardar, se revisa una clave que identifica esta operación en particular, para que un doble toque no registre la misma sesión dos veces | Verificación de operación repetida | **Idempotencia** |
| 9 | Se traduce el aviso de sesión completada al formato que espera el servicio externo de notificaciones | Conector hacia el proveedor externo | **Adapter** |
| 10 | El servicio de notificación procesa el aviso y responde | Servicio externo | — |
| 11 | Se guardan la sesión de entrenamiento y el logro pendiente asociado como una sola operación conjunta: o se guardan las dos cosas, o no se guarda ninguna | Persistencia de datos | **Repository + Unit of Work** (`db.transaction()` de sqflite) |
| 12 | Una vez guardada la sesión, se avisa a quienes deben reaccionar (actualizar el contador de logros en pantalla, enviar el correo de confirmación) sin que `iniciarRutina` tenga que conocer a cada uno por nombre | Notificación de eventos internos | **Observer** |
| 13 | Si el servicio de notificación tarda demasiado o falla de forma repetida, se deja de insistir tras un tiempo límite, sin bloquear el registro local de la rutina (que no depende de que el correo se envíe) | Protección ante fallas del proveedor externo | **Timeout + Circuit Breaker** |
| 14 | Se arma la respuesta para el usuario confirmando las calorías registradas, sin depender de "no recargue" como única medida de seguridad | Formato de salida | Plantilla de salida (adaptada al tipo de cliente que la pidió) |

---

## 4. Misión 3 — Políticas transversales

### a) Cuándo y por qué conviene una sola puerta de entrada (Front Controller)

En este proyecto la revisión de sesión en `inicio.dart` no hace nada (el `if` tiene el cuerpo vacío), y ninguna otra pantalla revisa nada en absoluto. Conviene centralizar esta revisión en el enrutador de la app (`onGenerateRoute`) para que sea imposible "olvidar" la revisión en una pantalla nueva, como ya pasó aquí en las seis pantallas existentes.

### b) Qué ya traen los marcos de trabajo modernos para esto

Flutter ya ofrece `onGenerateRoute` para centralizar la construcción de pantallas con guardas antes de navegar, y `flutter_bloc` ya resuelve el problema de Observer con streams que se cierran solos — de hecho el proyecto **ya pagó el costo** de incluir `flutter_bloc` y hasta de escribir un `Cubit` (`RelojCubit`) correctamente, solo falta conectarlo en vez de usar la lista estática casera.

### c) Orden correcto de la revisión previa

1. *Autenticación* — confirmar que existe una sesión válida antes de mostrar cualquier pantalla protegida.
2. *Validación de negocio* — confirmar que no haya ya una rutina en curso para ese usuario.
3. *Bitácora* — dejar constancia de que la acción ocurrió.
4. *Caso de uso* — ejecutar el inicio de la rutina en sí.

Registrar la sesión de entrenamiento antes de confirmar la identidad del usuario es un error grave: si después resulta que no había sesión válida, esa sesión de entrenamiento queda huérfana, sin saber a quién pertenece.

### d) Qué NO debe ir dentro de esa cadena de guardas previas

No deben colocarse ahí las reglas específicas de cada rutina (cuántas calorías corresponden a cada tipo). Esas decisiones pertenecen al caso de uso concreto (`iniciarRutina`) y deben vivir dentro de él, no en una guarda genérica que se ejecuta para toda la navegación por igual.
