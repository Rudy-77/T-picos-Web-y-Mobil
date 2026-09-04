# Auditoría de arquitectura — Portal universitario (caso de estudio)

Este documento recoge una revisión archivo por archivo del proyecto, identificando en cada uno la práctica deficiente encontrada y ubicando con precisión el archivo y la línea donde se presenta.

---

## 1. Diagnóstico general

### 1.1 Sobre los patrones de diseño

Al examinar el proyecto de forma exhaustiva, no se identificó un solo patrón de diseño implementado de manera completa o intencional. Existen ciertos indicios de que alguien buscó dar orden al código —por ejemplo, aislando la conexión a la base de datos en un archivo aparte, o concentrando funciones dentro de `global/funciones.php`—, pero en ningún caso ese esfuerzo termina pareciéndose, ni siquiera de lejos, al patrón que intenta imitar.

- El archivo `config/db_connect.php` sugiere el inicio de una configuración desacoplada del código, pero la contraseña sigue estando escrita ahí mismo, por lo que nunca cumple el propósito real de ese enfoque: mantener los secretos fuera del código fuente.
- Concentrar funciones en `global/funciones.php` simula una capa de utilidades, pero en realidad se trata de cientos de funciones prácticamente idénticas, apiladas por copiar y pegar, sin nada genuinamente reutilizable.

Tampoco se sigue el modelo MVC ni ninguna arquitectura por capas: no existe un punto de entrada único, y la lógica de negocio, la presentación y el acceso a datos están completamente entremezclados. Cada archivo PHP opera como un script independiente que resuelve las tres responsabilidades a la vez, invocando cada pieza donde se necesita en lugar de coordinarlas desde un solo lugar.

### 1.2 Problemas encontrados

| Archivo / carpeta | Situación observada | Consecuencia |
|---|---|---|
| `index.php`, línea 3 | Se apaga completamente el reporte de errores de PHP | Los fallos pasan inadvertidos tanto para el equipo de desarrollo como para soporte; nadie se percata cuando algo deja de funcionar |
| `index.php`, línea 6 | Con solo crear una cookie llamada `admin_bypass` se obtiene sesión de administrador | Funciona como una puerta trasera que cualquiera con conocimientos mínimos podría explotar sin necesidad de credenciales |
| `index.php`, a partir de la línea 8 | Cientos de clases CSS repetidas y sin ningún uso real, todas con el mismo patrón de nombre | Se trata de código muerto que infla el archivo y dificulta encontrar la parte que sí es funcional |
| `pagar.php` | Un `switch` con treinta bloques prácticamente iguales, uno por banco, cada uno invocando un servicio SOAP propio y validando su propio código de estado | Sumar un banco nuevo exige copiar y pegar un bloque entero; un error mínimo en cualquiera de los treinta pasa fácilmente inadvertido |
| `pagar.php`, dentro de los `case` | La tabla de pagos se actualiza marcando todos los registros como pagados, sin ninguna condición que aísle el registro correspondiente | Esta instrucción afecta a todos los pagos de la tabla, no solo al del alumno en turno; no es un descuido menor, sino un error crítico |
| `pagar.php` / `pagar1.php` | No existe protección alguna contra ejecutar dos veces la misma operación de pago | Un doble clic accidental puede generar un cobro duplicado real en la tarjeta del alumno |
| `kardex.php`, primeras líneas | Diez condicionales anidados solo para excluir matrículas de prueba | El código resulta difícil de leer y mantener; sumar una matrícula más obliga a añadir otro nivel de anidamiento |
| `kardex.php`, línea 14 en adelante | Dentro del ciclo que recorre las materias del alumno se lanza una nueva consulta SQL por cada una, y en `kardex1.php` se suma una tercera consulta por cada profesor | Un historial de cuarenta materias puede generar más de ochenta consultas para renderizar una sola pantalla, ralentizando la página y saturando la base de datos sin necesidad |
| `kardex.php` | Un ciclo que calcula mil veces un hash que jamás se utiliza | Es procesamiento desperdiciado que únicamente retrasa la respuesta de la página |
| `global/funciones.php` (2001 líneas) | Aproximadamente seiscientas funciones casi idénticas, cada una sustituyendo un número distinto por la letra X | Es la misma función duplicada seiscientas veces variando un solo valor; bastaría una función única que reciba ese valor como parámetro |
| `js1/utilerias1.js` | Se repite el mismo patrón de copiar y pegar, ahora en el lado del cliente | La duplicación no se limita al servidor: también contamina el código que se ejecuta en el navegador del usuario |
| `config/db_connect.php`, `config/db_connect_produccion.php`, `config1/db_connect1.php`, `config1/db_connect_produccion1.php`, además de `login1.php`, `kardex1.php` y `pagar1.php` | La contraseña de la base de datos aparece escrita directamente en el código, incluyendo una contraseña real de producción | Cualquiera con acceso al repositorio puede leer y usar esa contraseña real; además, al estar duplicada en cuatro archivos, actualizarla implica no olvidar ninguno de los cuatro |
| `api.php`, línea 5 | Cualquier texto enviado por POST se ejecuta directamente como código PHP | Es equivalente a dejar la puerta principal del servidor abierta: quien localice esa ruta puede ejecutar lo que quiera |
| `api.php`, línea 7 | Se devuelve el contenido de cualquier archivo señalado mediante un parámetro en la URL | Habilita la lectura de cualquier archivo del servidor, incluyendo los que contienen credenciales de configuración |
| `login1.php`, línea 8 | La consulta de inicio de sesión se construye concatenando directamente la entrada del usuario, dejando abierta la inyección SQL | Basta con introducir un valor especial en el formulario para alterar la consulta y acceder sin conocer la contraseña real |
| `login1.php`, línea 8 | La contraseña se compara directamente contra el valor almacenado, sin cifrado de por medio | Si alguien obtiene una copia de la base de datos, accede de inmediato a las contraseñas de todos los usuarios en texto plano |
| `login1.php`, líneas 13-14 e `index1.php`, línea 4 | La sesión se gestiona con dos mecanismos simultáneos: una cookie y la sesión nativa de PHP | Como la cookie la controla el navegador y no el servidor, basta con modificarla manualmente para suplantar a un administrador sin necesidad de contraseña |
| `index1.php`, línea 8 | La condición de la consulta de perfil se arma pegando directamente un valor tomado de la URL | Reaparece el mismo problema de inyección SQL, ahora sobre la consulta de perfil de cualquier usuario |
| `pagar1.php`, líneas 14-16 | El número de tarjeta y el código de seguridad se transmiten en texto plano hacia un servicio externo | Los datos financieros viajan sin ninguna protección adicional; cualquier falla en ese envío expone información sensible |
| `pagar1.php`, línea 11 | El monto que se cobra está fijo en el código, sin relación con la deuda real del alumno | El sistema cobra siempre la misma cifra, sin importar cuánto deba realmente el alumno por su inscripción |
| `documentacion/diagrama_base_datos.txt` | Describe tablas y reglas que no corresponden con el código ni con el script real de la base de datos | La documentación no refleja lo que el sistema hace en realidad; confiar en ella lleva a modificar tablas irrelevantes y dejar sin tocar las que sí importan |
| `bd/script_produccion_real_no_tocar.sql` | Cincuenta tablas vacías, sin relación con el resto del sistema, mezcladas entre las tablas reales | Ese contenido inutilizado se mezcla con el real, dificultando identificar qué tabla es la que verdaderamente importa |
| `index.php` / `index1.php`, `kardex.php` / `kardex1.php`, `pagar.php` / `pagar1.php` | Existen dos versiones distintas de una misma funcionalidad, cada una con sus propias reglas de negocio | No es claro cuál versión está realmente activa; ambas duplican el esfuerzo de mantenimiento y aumentan el riesgo de que una quede desactualizada sin que nadie lo detecte |

### 1.3 ¿Refactorizar gradualmente o reconstruir por completo?

La recomendación es **reconstruir la arquitectura desde cero**, usando el código actual únicamente como referencia para entender las reglas de negocio (qué debe suceder al pagar, qué información debe mostrar el kardex), y no como base sobre la cual editar directamente.

Lo que sí vale la pena conservar del proyecto actual es el modelo de datos base —una vez eliminadas las tablas abandonadas— junto con las reglas de negocio que puedan identificarse con claridad, como los rangos de calificación del kardex o el flujo general de cobro, alta de materias y notificación.

---

## Misión 1 — El portal no sigue ningún patrón

| # | Problema identificado en el proyecto | Capa afectada | Patrón(es) que lo resuelve | Por qué este patrón y no el que suele confundirse | Cuándo no conviene aplicarlo |
|---|---|---|---|---|---|
| 1 | No hay un punto de entrada único: la sesión, las cookies y la autorización se validan de forma distinta en cada archivo (`index.php`, `index1.php`, `kardex1.php`, `pagar1.php`) | Políticas transversales | Front Controller + Chain of Responsibility | La cadena puede interrumpir la petición si alguna validación falla, por ejemplo ante una sesión inválida. Suele confundirse con Decorator, pero este último siempre envuelve la petición dejándola continuar, no está diseñado para detenerla | En un sitio con dos o tres páginas fijas, sin planes de expansión, centralizar la entrada costaría más configuración de la que realmente aporta |
| 2 | `pagar.php` implementa un switch de treinta casos casi idénticos, uno por banco, cada uno con su propio protocolo SOAP y códigos de estado propios | Aplicación/dominio e integración | Strategy para seleccionar el algoritmo de cobro, Adapter para traducir cada protocolo bancario a un formato común | Suele confundirse con Factory, pero Factory decide qué objeto crear; aquí el alumno ya definió el método de pago desde el formulario, así que lo que varía es el algoritmo de cobro, no el tipo de objeto | Si el sistema operara con un solo banco, sin planes de agregar otro, construir una interfaz con una única implementación sería sobreingeniería |
| 3 | `kardex.php` y `kardex1.php` ejecutan SQL directo dentro del mismo script que genera la salida en pantalla, y disparan una consulta nueva por cada materia dentro de un ciclo | Presentación (servidor) y datos | Repository + Service Layer | Se confunde con Facade, que agrupa llamadas a un subsistema propio para simplificar su uso, pero no resuelve que la vista tenga SQL mezclado con HTML. Repository es exactamente la pieza faltante: una capa que aísla el acceso a los datos | Si se tratara de una consulta simple, usada una sola vez y sin reutilización en otros reportes, no se justifica construir toda una capa de repositorio |
| 4 | `pagar.php` actualiza la tabla de pagos sin ninguna condición que la vincule a un alumno o pago específico, y no existe control contra el doble clic | Aplicación/dominio y datos | Idempotencia (clave de operación) + Unit of Work | Corregir únicamente la condición de la consulta no impide que la misma petición se dispare dos veces | Si el cobro fuera un paso completamente sincronizado y el banco garantizara que un mismo folio nunca se cobra dos veces, esta capa resultaría innecesaria |
| 5 | `global/funciones.php` concentra alrededor de seiscientas funciones casi idénticas, cada una sustituyendo un número distinto por la letra X | Aplicación/dominio, utilidades compartidas | Una única función parametrizada, sin necesidad de Strategy | Strategy se justifica cuando el comportamiento cambia entre variantes; aquí el comportamiento es idéntico, solo varía un valor de entrada, así que un parámetro es suficiente | Cuando el comportamiento realmente difiere entre casos —no solo un valor—, forzarlo dentro de una única función con múltiples if sí sería un error; ahí sí conviene Strategy |
| 6 | Las credenciales de la base de datos están escritas directamente en el código y se repiten en cuatro archivos distintos, incluyendo una contraseña real de producción | Datos e integración, configuración transversal | Externalización de configuración mediante variables de entorno + un único punto de conexión | Aun unificando los cuatro archivos, la contraseña real seguiría expuesta en el código fuente; la solución real es sacar el secreto del código y centralizar la conexión en un solo lugar | En un script personal, de uso único y sin datos sensibles reales, escribir la conexión directamente en el código es aceptable |

---

## Misión 2 — Una petición, distintos patrones

### Comportamiento actual del código

No existe un camino único para pagar la inscripción: el proyecto mantiene dos versiones distintas y contradictorias entre sí, `pagar.php` y `pagar1.php`, cada una accesible desde su propia dirección, sin pasar por ningún punto de control compartido y sin claridad sobre cuál está realmente vigente.

### Flujo propuesto tras la corrección

| Paso | Qué sucede | Tipo de componente | Patrón que representa |
|---|---|---|---|
| 1 | El alumno completa el formulario de pago (monto, método) y presiona Pagar | Vista del cliente | Interfaz de usuario, fuera del alcance del backend |
| 2 | El formulario se envía como `POST /pagos` al servidor | Petición HTTP | — |
| 3 | La petición ingresa por un único punto de recepción del portal, en lugar de llegar directamente a un archivo aislado | Enrutador de entrada | Front Controller |
| 4 | Antes de continuar hacia la lógica de pago se valida, en secuencia, que la sesión sea válida, que el alumno tenga cupo disponible, y se registra el intento en bitácora; cualquiera de estas verificaciones puede detener la petición | Middleware / filtros previos | Chain of Responsibility |
| 5 | Un componente recibe los datos ya validados e invoca el caso de uso de negocio correspondiente, sin tomar decisiones por su cuenta | Controlador de la operación | Controlador delgado: recibe la entrada, no decide el negocio |
| 6 | Se ejecuta la operación de pago de inscripción con el alumno, el método y el monto correspondientes | Capa de casos de uso | Service Layer |
| 7 | Dentro de esa operación se selecciona la forma de cobro según el método elegido | Selector de algoritmo de cobro | Strategy |
| 8 | Antes de ejecutar el cobro se verifica una clave que identifica esta operación en particular, evitando que un doble clic genere un segundo cargo | Verificación de operación repetida | Idempotencia |
| 9 | La solicitud de cobro se traduce al formato que entiende el banco o la pasarela externa, y su respuesta se traduce de vuelta a un formato interno común | Conector hacia el proveedor externo | Adapter |
| 10 | El banco procesa el cobro y devuelve un código de resultado | Servicio externo | — |
| 11 | Si el cobro se completó con éxito, se registra el cargo del alumno y el alta de materias como una sola operación conjunta: ambas cosas se guardan o ninguna | Persistencia de datos | Repository + Unit of Work |
| 12 | Una vez confirmado el pago, se notifica a quienes deben reaccionar (correo al alumno, aviso a control escolar, actualización de caja), sin que la operación de pago necesite conocer individualmente a cada destinatario | Notificación de eventos internos | Observer |
| 13 | Si el banco tarda demasiado o falla repetidamente, se corta la espera tras un límite de tiempo y se detiene la insistencia mientras persista el problema, sin afectar al resto del sistema (el kardex, independiente del banco, sigue funcionando) | Protección ante fallas del proveedor externo | Timeout + Circuit Breaker |
| 14 | Se construye la respuesta para el alumno confirmando el pago y, en su caso, el detalle de las materias inscritas | Formato de salida | Plantilla de salida, adaptada al tipo de cliente que hizo la solicitud |

---

## Misión 3 — Políticas transversales

**Por qué conviene una única puerta de entrada:** en el estado actual del proyecto, la validación de sesión se resuelve de manera distinta en cada archivo: `index.php` revisa la sesión y adicionalmente acepta una cookie de puerta trasera, `index1.php` verifica una cookie junto con la sesión, y `kardex1.php` no valida nada en absoluto. Cuando la misma responsabilidad —confirmar la identidad del usuario, verificar sus permisos y registrar el intento— se implementa por separado en cada archivo, tarde o temprano alguna de esas copias queda incompleta o se olvida, tal como ocurrió aquí. Una puerta de entrada única resulta conveniente cuando varias rutas del sistema deben pasar por las mismas validaciones antes de ejecutarse: escribir esa lógica una sola vez y centralizar el paso por ahí evita que se duplique —y se desactualice— en cada archivo por separado.

**Lo que los frameworks modernos ya resuelven:** los frameworks actuales incorporan el mecanismo de middleware, que permite declarar en un único lugar la secuencia de validaciones que debe superar una petición antes de llegar a la lógica de negocio, sin necesidad de programar manualmente cada revisión dentro de cada archivo. No es necesario construir una cadena de filtros desde cero.

**Secuencia correcta de validación previa:**
1. **Autenticación** — confirmar la identidad de quien realiza la petición.
2. **Validación de negocio** — por ejemplo, el cupo disponible, para confirmar que esa persona puede ejecutar la acción.
3. **Bitácora** — dejar constancia de que la petición tuvo lugar.
4. **Caso de uso** — ejecutar la acción de negocio propiamente dicha.

Cobrar antes de autenticar constituye un error grave: si el cobro ocurre primero y la identidad se confirma después, el sistema podría terminar cobrando a alguien que ni siquiera logró comprobar quién es; y si esa autenticación falla una vez realizado el cobro, ya no existe forma limpia de determinar a quién pertenece ese dinero ni cómo revertirlo con seguridad. El orden correcto impide que el sistema ejecute una acción irreversible antes de tener certeza sobre la identidad con la que está tratando.

**Lo que no debe formar parte de esa cadena de filtros:** las decisiones propias del negocio específico de cada operación no deben ubicarse ahí. Esas decisiones dependen del caso de uso concreto —ya sea pagar o consultar el kardex— y deben residir dentro de esa operación, no en un filtro genérico que se ejecuta por igual para todas las peticiones. Incorporar reglas de negocio dentro de los filtros previos vuelve esos filtros poco reutilizables y mezcla, innecesariamente, elementos que deberían mantenerse separados.
