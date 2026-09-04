# Auditoría de arquitectura — Portal universitario (caso de estudio)

Se revisó cada archivo buscando qué práctica deficiente presenta, señalando en cada caso el archivo y la línea donde aparece.

---

## 1. Panorama general

### 1.1 Patrones de diseño

Tras revisar el proyecto archivo por archivo, no se encontró ningún patrón de diseño aplicado de manera completa ni deliberada. Hay indicios de que alguien intentó ordenar el código, por ejemplo separando la conexión a la base de datos en su propio archivo, o juntando funciones dentro de `global/funciones.php`, pero en ningún caso ese intento llega a comportarse como el patrón que aparenta imitar, ni siquiera de forma aproximada.

- La separación de `config/db_connect.php` parece el arranque de una configuración externa al código, pero la contraseña sigue quedando escrita dentro del archivo, así que no logra el objetivo real de ese patrón, que es sacar el secreto fuera del código fuente.
- Agrupar funciones en `global/funciones.php` da la apariencia de una capa de utilidades, pero en realidad son cientos de funciones casi iguales, copiadas y pegadas una tras otra, sin nada verdaderamente reutilizable.

El proyecto tampoco sigue MVC, ni una arquitectura por capas, no tiene un punto único de entrada, y no separa la lógica de negocio de la presentación ni del acceso a datos. Cada archivo PHP funciona como un script suelto que mezcla las tres cosas al mismo tiempo, llamando a cada parte donde hace falta en lugar de centralizar esos llamados.

### 1.2 Malas prácticas detectadas

| Archivo / carpeta | Qué se observa | Por qué es un problema |
|---|---|---|
| `index.php`, línea 3 | Se desactiva por completo el reporte de errores de PHP | Cualquier falla queda invisible, tanto para quien desarrolla como para quien da soporte; nadie se entera cuando algo se rompe |
| `index.php`, línea 6 | Basta con crear una cookie llamada `admin_bypass` para que el sistema otorgue sesión de administrador | Se trata de una puerta trasera que cualquier persona con conocimientos básicos puede aprovechar sin necesidad de contraseña |
| `index.php`, a partir de la línea 8 | Cientos de clases CSS sin uso real, repetidas con el mismo patrón de nombre | Es código muerto que solo agrega peso al archivo y complica localizar la parte que sí funciona |
| `pagar.php` | Un `switch` con treinta casos casi idénticos, uno por banco, cada uno llamando a un servicio SOAP distinto y comparando un código de estado propio | Agregar un banco nuevo implica copiar y pegar un bloque completo; un error de dedo en uno solo de esos treinta bloques pasa fácilmente desapercibido |
| `pagar.php`, dentro de los `case` | Se actualiza la tabla de pagos marcando todo como pagado, sin ninguna condición que filtre el registro correcto | Esa instrucción marca como pagados todos los registros de la tabla, no solo el del alumno que está pagando en ese momento; es un error grave, no un simple descuido de estilo |
| `pagar.php` / `pagar1.php` | No existe ningún mecanismo que evite ejecutar la misma operación de pago dos veces | Un doble clic accidental puede traducirse en un cobro duplicado real sobre la tarjeta del alumno |
| `kardex.php`, primeras líneas | Diez condicionales anidados uno dentro de otro solo para descartar matrículas de prueba | Es difícil de leer y de mantener; agregar una matrícula más a la lista implica añadir otro nivel de anidamiento |
| `kardex.php`, línea 14 en adelante | Dentro del ciclo que recorre las materias del alumno se dispara una consulta SQL nueva por cada materia, y en `kardex1.php` una tercera consulta por cada profesor | Un historial de cuarenta materias puede disparar más de ochenta consultas para armar una sola pantalla, lo que vuelve la página lenta y sobrecarga innecesariamente la base de datos |
| `kardex.php` | Un ciclo que calcula mil veces un hash que nunca se usa | Es trabajo que no aporta nada y solo hace que la página tarde más en responder |
| `global/funciones.php` (2001 líneas) | Cerca de seiscientas funciones casi idénticas, cada una reemplazando un número distinto por la letra X | Es la misma función copiada seiscientas veces cambiando un solo valor; debería existir una única función que reciba ese valor como parámetro |
| `js1/utilerias1.js` | El mismo patrón de copiar y pegar, ahora del lado del navegador | La duplicación no se queda en el servidor, se repite también en el código que corre en la máquina del usuario |
| `config/db_connect.php`, `config/db_connect_produccion.php`, `config1/db_connect1.php`, `config1/db_connect_produccion1.php`, y además dentro de `login1.php`, `kardex1.php` y `pagar1.php` | La contraseña de la base de datos está escrita directamente en el código, y en el archivo de producción aparece una contraseña real | Cualquiera con acceso al código puede leer y usar la contraseña real de producción; además la misma configuración está repetida en cuatro archivos, así que cambiarla implica recordar actualizarla en los cuatro lugares |
| `api.php`, línea 5 | Se ejecuta como código PHP cualquier texto enviado por POST | Equivale a dejar abierta la puerta principal del servidor: quien encuentre esa dirección puede ejecutar lo que quiera |
| `api.php`, línea 7 | Se devuelve el contenido de cualquier archivo indicado por parámetro en la URL | Permite leer cualquier archivo del servidor, incluidos los que guardan contraseñas de configuración |
| `login1.php`, línea 8 | La consulta de inicio de sesión se arma concatenando directamente lo que el usuario escribe, abriendo la puerta a inyección SQL | Alguien puede escribir un valor especial en el formulario para alterar el significado de la consulta y entrar sin conocer la contraseña real |
| `login1.php`, línea 8 | La contraseña se compara tal como está guardada, sin ningún cifrado | Si alguien obtiene una copia de la base de datos, tiene acceso directo a las contraseñas de todos los usuarios en texto legible |
| `login1.php`, líneas 13-14 e `index1.php`, línea 4 | El sistema recuerda la sesión con dos mecanismos distintos a la vez: una cookie y la sesión de PHP | La cookie la controla el navegador del usuario, no el servidor; basta con editarla a mano para hacerse pasar por administrador sin conocer ninguna contraseña |
| `index1.php`, línea 8 | La consulta del perfil arma su condición pegando directamente un valor tomado de la URL | Se repite el mismo problema de inyección SQL, ahora aplicado a la consulta de perfil de cualquier usuario |
| `pagar1.php`, líneas 14-16 | El número de tarjeta y el código de seguridad se arman como texto plano y se envían a un servicio externo | Los datos financieros viajan sin protección adicional; cualquier falla en ese envío expone información sensible |
| `pagar1.php`, línea 11 | El monto a cobrar queda fijo en el código, sin relación con lo que realmente debe el alumno | El sistema cobra siempre la misma cantidad sin importar el monto real de la inscripción |
| `documentacion/diagrama_base_datos.txt` | Describe tablas y reglas que no existen en el código ni coinciden con el script real de base de datos | La documentación entregada no corresponde a lo que el sistema realmente hace; alguien que confíe en ella terminará modificando tablas que no se usan y dejando intactas las que sí importan |
| `bd/script_produccion_real_no_tocar.sql` | Cincuenta tablas vacías sin relación con el resto del sistema, mezcladas con las tablas reales | Es contenido que nadie usa mezclado con el contenido real, lo que dificulta identificar qué tabla importa de verdad |
| `index.php` / `index1.php`, `kardex.php` / `kardex1.php`, `pagar.php` / `pagar1.php` | Existen dos versiones distintas de la misma función del sistema, con reglas de negocio diferentes entre sí | No queda claro cuál de las dos versiones está realmente en uso; ambas duplican el trabajo de mantenimiento y aumentan el riesgo de que una quede desactualizada sin que nadie lo note |

### 1.3 ¿Corregir poco a poco o reconstruir desde cero?

Se recomienda **reconstruir la arquitectura desde cero**, tomando el código actual únicamente como referencia de las reglas de negocio (qué debe pasar cuando alguien paga, qué debe mostrar el kardex), y no como punto de partida para editar línea por línea.

Lo que sí conviene rescatar del proyecto actual es el modelo de datos base, una vez depurado de las tablas abandonadas, junto con las reglas de negocio que sí se pueden identificar con claridad, como los rangos de calificación del kardex o el flujo general de cobrar, dar de alta materias y avisar.

---

## Misión 1 — El portal no es un patrón

| # | Problema detectado en el proyecto | Capa afectada | Patrón(es) que lo resuelve | Por qué ese y no el vecino que suele confundirse | Cuándo no conviene aplicarlo |
|---|---|---|---|---|---|
| 1 | No hay un punto único de entrada: la sesión, las cookies y la autorización se revisan de forma distinta en cada archivo (`index.php`, `index1.php`, `kardex1.php`, `pagar1.php`) | Políticas transversales | Front Controller + Chain of Responsibility | La cadena puede detener la petición si alguna revisión falla, por ejemplo cuando no hay sesión válida. El patrón que suele confundirse aquí es Decorator, pero Decorator siempre envuelve la petición y la deja pasar, no está pensado para frenarla | Si el sitio tuviera solo dos o tres páginas fijas sin planes de crecer, centralizar la entrada costaría más configuración de la que aporta |
| 2 | `pagar.php` es un switch de treinta casos casi idénticos, uno por banco, cada uno con su propio protocolo SOAP y sus propios códigos de estado | Aplicación/dominio e integración | Strategy para elegir el algoritmo de cobro, Adapter para traducir cada protocolo bancario a un formato común | El vecino que se suele confundir es Factory, pero Factory decide qué objeto crear; aquí el alumno ya eligió el método de pago en el formulario, lo que cambia es el algoritmo de cobro en sí, no el tipo de objeto | Si el sistema trabajara con un único banco, sin planes de sumar otro, montar una interfaz con una sola implementación sería complejidad de más |
| 3 | `kardex.php` y `kardex1.php` ejecutan SQL directo dentro del script que arma la salida en pantalla, y disparan una consulta nueva por cada materia dentro de un ciclo | Presentación (servidor) y datos | Repository + Service Layer | El vecino que se confunde es Facade, que agrupa llamadas a un subsistema propio para simplificar su uso, pero no resuelve que la vista tenga SQL mezclado con HTML. Repository es la pieza exacta que falta: una capa que aísla cómo se consultan los datos | Si fuera una sola consulta simple, usada una única vez y que no se repite en ningún otro reporte, no se justifica construir toda una capa de repositorio |
| 4 | `pagar.php` actualiza la tabla de pagos sin condición que la ligue a un alumno o pago específico, y no hay control alguno contra el doble clic | Aplicación/dominio y datos | Idempotencia (clave de operación) + Unit of Work | Corregir solo la condición de la consulta no evita que la misma petición se ejecute dos veces | Si el cobro fuera un paso totalmente sincronizado y el banco garantizara que un mismo folio jamás se cobra dos veces, esta capa sería innecesaria |
| 5 | `global/funciones.php` reúne cerca de seiscientas funciones casi idénticas, cada una reemplazando un número distinto por la letra X | Aplicación/dominio, utilidades compartidas | Una sola función parametrizada, sin necesidad de Strategy | Strategy tiene sentido cuando el comportamiento cambia entre variantes; aquí el comportamiento es exactamente el mismo, solo cambia un valor de entrada, así que basta un parámetro | Cuando el comportamiento sí cambia de verdad entre casos, y no solo un valor, forzarlo dentro de una única función con muchos if sería el error; ahí conviene Strategy |
| 6 | Las credenciales de la base de datos están escritas directamente en el código y repetidas en cuatro archivos distintos, incluida una contraseña real de producción | Datos e integración, configuración transversal | Externalización de configuración mediante variables de entorno + un único punto de conexión | Aunque se unificaran los cuatro archivos, la contraseña real seguiría dentro del código fuente; lo que corrige el problema es sacar el secreto del código y tener un solo lugar que arme la conexión | En un script personal, de un solo uso y sin datos sensibles reales, escribir la conexión directamente en el código resulta aceptable |

---

## Misión 2 — Una petición, varios patrones

### Lo que hace el código actualmente

No existe un único camino para pagar la inscripción: el proyecto tiene dos versiones distintas y contradictorias entre sí, `pagar.php` y `pagar1.php`, cada una accesible por su propia dirección, sin pasar por ningún punto de control común y sin que quede claro cuál de las dos está vigente.

### Camino corregido a seguir

| Paso | Qué ocurre | Tipo de componente | Patrón que representa |
|---|---|---|---|
| 1 | El alumno llena el formulario de pago (monto, método) y da clic en Pagar | Vista del cliente | Interfaz del lado del usuario, fuera del alcance del backend |
| 2 | El formulario se envía como `POST /pagos` hacia el servidor | Petición HTTP | — |
| 3 | La petición entra por un único punto de recepción del portal, en vez de llegar directo a un archivo suelto | Enrutador de entrada | Front Controller |
| 4 | Antes de llegar a la lógica de pago se revisa, en orden, que la sesión sea válida, que el alumno tenga cupo, y se registra el intento en bitácora; cualquiera de estas revisiones puede detener la petición | Middleware / filtros previos | Chain of Responsibility |
| 5 | Un componente recibe los datos ya validados y llama al caso de uso de negocio, sin decidir reglas por su cuenta | Controlador de la operación | Controlador delgado, recibe la entrada, no decide el negocio |
| 6 | Se invoca la operación de pagar la inscripción con el alumno, el método y el monto | Capa de casos de uso | Service Layer |
| 7 | Dentro de esa operación se elige cómo cobrar según el método elegido | Selector de algoritmo de cobro | Strategy |
| 8 | Antes de ejecutar el cobro se revisa una clave que identifica esta operación en particular, para que un doble clic no dispare un segundo cobro | Verificación de operación repetida | Idempotencia |
| 9 | Se traduce la petición de cobro al formato que entiende el banco o la pasarela externa, y también se traduce su respuesta a un formato interno común | Conector hacia el proveedor externo | Adapter |
| 10 | El banco procesa el cobro y responde con un código de resultado | Servicio externo | — |
| 11 | Si el cobro fue exitoso, se guarda el cargo del alumno y el alta de las materias como una sola operación conjunta: se guardan las dos cosas o ninguna | Persistencia de datos | Repository + Unit of Work |
| 12 | Una vez confirmado el pago, se avisa a quienes deben reaccionar (correo al alumno, aviso a control escolar, actualización de caja), sin que la operación de pago necesite conocer a cada uno de ellos por nombre | Notificación de eventos internos | Observer |
| 13 | Si el banco tarda demasiado o falla de forma repetida, se deja de esperar tras un límite de tiempo y se evita seguir insistiendo mientras el problema continúe, sin bloquear el resto del sistema (el kardex, que no depende del banco, sigue funcionando) | Protección ante fallas del proveedor externo | Timeout + Circuit Breaker |
| 14 | Se arma la respuesta para el alumno confirmando el pago y, si corresponde, el detalle de las materias inscritas | Formato de salida | Plantilla de salida, adaptada al tipo de cliente que la pidió |

---

## Misión 3 — Políticas transversales

**Cuándo y por qué conviene una sola puerta de entrada:** en el proyecto actual, la revisión de sesión se hace de forma distinta en cada archivo: `index.php` revisa la sesión y además acepta una cookie de puerta trasera, `index1.php` revisa una cookie y la sesión al mismo tiempo, y `kardex1.php` no revisa nada. Cuando la misma tarea —confirmar quién es el usuario, si tiene permiso, y dejar constancia del intento— se repite por separado en cada archivo, tarde o temprano alguna de esas copias queda mal hecha o se olvida, como sucedió aquí. Conviene una sola puerta de entrada cuando el sistema tiene varias rutas que necesitan pasar por las mismas revisiones antes de ejecutarse: escribir esa revisión una sola vez y hacer que todo pase por ahí evita que se repita, y se desactualice, en cada archivo por separado.

**Qué ya traen los marcos de trabajo modernos:** los frameworks actuales ya incluyen el mecanismo de middleware, que permite declarar en un solo lugar la lista de revisiones que debe superar una petición antes de llegar a la lógica de negocio, sin tener que escribir a mano el código que revisa cada cosa dentro de cada archivo. No hace falta construir una cadena de filtros propia.

**Orden correcto de la revisión previa:**
1. **Autenticación** — confirmar quién hace la petición.
2. **Validación de negocio** — como el cupo disponible, para confirmar que esa persona puede realizar la acción.
3. **Bitácora** — dejar constancia de que la petición ocurrió.
4. **Caso de uso** — ejecuta la acción de negocio en sí.

Cobrar antes de autenticar es un error grave: si el cobro ocurre primero y la identidad se confirma después, el sistema puede terminar cobrando a alguien que ni siquiera pudo demostrar quién es, y si esa autenticación falla después del cobro ya no hay una forma limpia de saber a quién pertenece ese dinero ni cómo revertirlo con seguridad. El orden correcto evita que el sistema tome una acción irreversible antes de tener certeza sobre con quién está tratando.

**Qué no debe ir dentro de esa cadena de filtros:** no deben colocarse ahí las decisiones que pertenecen al negocio específico de cada operación. Esas decisiones dependen del caso de uso concreto, sea pagar o consultar el kardex, y deben vivir dentro de esa operación, no en un filtro genérico que se ejecuta igual para todas las peticiones. Meter reglas de negocio dentro de los filtros previos vuelve esos filtros difíciles de reutilizar y mezcla, sin necesidad, cosas que deberían mantenerse separadas.
