# Portal universitario — análisis de patrones de diseño

## El problema

Una universidad pública mantiene el alta de materias, el pago de inscripción, las constancias y las becas en decenas de páginas sueltas (PHP, ASP clásico y un par de servicios nuevos). Se requiere un portal web único para el siguiente ciclo.

El estado actual, documentado por control escolar y por caja, es el siguiente:

1. Cada trámite es un archivo distinto. En todos se copia el mismo bloque de ¿hay sesión?, el mismo registro en bitácora y el mismo encabezado HTML. Cuando cambia la regla de caducidad de la sesión, hay que tocar cuarenta archivos; siempre se olvida uno.
2. El pago de inscripción admite tarjeta, transferencia SPEI y referencia de ventanilla. El script de pagar.php es un switch de doscientas líneas. Cada banco nuevo obliga a editar ese archivo. El protocolo de un banco habla de créditos y códigos 00/01; el reglamento interno habla de pago de inscripción y estados pendiente/acreditado/rechazado.
3. La plantilla del kardex ejecuta consultas SQL para armar la tabla de calificaciones. Los reportes de constancias duplican esas consultas con otro formato.
4. Cuando el pago se acredita, el mismo script llama a control escolar (alta de materias), dispara un correo al estudiante y avisa a caja. Si el correo falla, a veces no se registra el alta. Si el estudiante pulsa dos veces pagar porque la página tarda, se han cobrado dos cargos.
5. La aplicación móvil de la universidad y el kiosco de la biblioteca deben mostrar el mismo trámite. La app pide un JSON mínimo (folio, saldo, plazo). El kiosco pide una página HTML con el escudo y la tabla de vencimientos. Hoy el equipo de la app hace doce peticiones para pintar la pantalla de inicio.
6. El servicio de un banco y el de un validador de CURP externo se caen con frecuencia. Mientras no responden, el estudiante ve la rueda de espera y no puede ni consultar el kardex, que no depende de esos colaboradores.
7. Un proveedor propone, para la descarga de una constancia en PDF, Event Sourcing, CQRS, una malla de microservicios y un almacén global Redux en el navegador. El trámite de la constancia es: autenticar, consultar un registro ya existente y generar un archivo.

El portal nuevo puede construirse en Spring, en Laravel o en Express: el análisis de patrones no espera un marco concreto. Sí espera que se use lo que el marco ya instancia (enrutador, middleware, transacción del ORM) y que no se copie un diagrama UML al lado.

## Misión 1 — El portal no es un patrón

Seis problemas del relato, con su capa, su patrón, el vecino que se descarta y el caso en que no aplicaría.

| Problema del relato | Capa | Patrón | Por qué ese y no el vecino | Cuándo no aplicaría |
|---|---|---|---|---|
| La sesión, la bitácora y el encabezado se copian en cuarenta archivos; cambiar la caducidad obliga a tocarlos todos | Políticas transversales / presentación | Front Controller + Chain of Responsibility (middleware) | El vecino sería Page Controller puro, un handler por archivo sin frontal compartido. Eso funciona si cada página es autónoma, pero aquí la política es la misma en todos los trámites, así que conviene centralizarla en un único punto de entrada con una cadena de responsabilidades | Si el portal tuviera una sola ruta, o si cada trámite necesitara reglas de sesión realmente distintas, montar un frontal y una cadena sería aparato de más |
| El script de pagar.php es un switch de doscientas líneas que crece con cada banco o medio de pago nuevo | Aplicación | Strategy | El vecino es Adapter, pero Adapter traduce el protocolo de un colaborador externo, mientras que aquí el problema es elegir cuál política de negocio propia se ejecuta (tarjeta, SPEI, ventanilla) | Si solo existiera un medio de pago, envolverlo en Strategy sería indirección sin beneficio |
| El protocolo del banco habla de crédito y códigos 00/01; el reglamento interno habla de pago de inscripción y estados pendiente/acreditado/rechazado | Integración | Adapter (anticorrupción) | El vecino es Facade, que simplifica el acceso a un subsistema propio compuesto de varias piezas internas. Aquí no hay un subsistema propio que simplificar, hay un vocabulario ajeno que traducir uno a uno | Si el banco ya hablara el lenguaje del dominio, no habría nada que traducir y el Adapter sería una capa vacía |
| Elegir qué cobrador instanciar según el medio que escogió el estudiante | Aplicación | Factory | El vecino es new disperso directamente en la ruta HTTP. Eso funciona para un caso, pero esparce la decisión de instanciación por todo el código. Factory la centraliza en un solo lugar | Si solo existiera un tipo de cobrador, instanciarlo directo es más simple que una fábrica |
| La plantilla del kardex ejecuta SQL directo para armar la tabla; los reportes de constancias duplican esas consultas con otro formato | Datos y vista | Repository + Template/Transform View, Service Layer | El vecino es el MVC degradado, o controlador-dios: meter la consulta y el formateo en el mismo lugar mezcla acceso a datos con presentación y duplica lógica entre kardex y constancias | Para una consulta de un solo uso, desechable, que nunca se reutiliza en otro reporte, envolverla en Repository sería capa de más |
| El cobro se acredita y el alta de materias debe registrarse junto con él; si el correo falla, a veces no se registra el alta | Datos | Unit of Work (transacción del ORM) | El vecino es Observer asíncrono ingenuo: notificar el alta como un evento desacoplado no garantiza que cobro y alta se confirmen o reviertan juntos. Aquí hace falta atomicidad transaccional, no notificación | Si el alta y el cobro vivieran en sistemas o bases de datos distintos sin transacción compartida, Unit of Work no sería posible y habría que usar una saga con compensación |

El portal no se resume como MVC ni como hexagonal, cada fila resuelve un conflicto puntual con su propia estructura.

## Misión 2 — Una petición, varios patrones

Caso de uso pagar la inscripción, desde el clic o el POST hasta persistir y notificar.

| Paso | Objeto o mecanismo | Patrón que realiza |
|---|---|---|
| 1 | El estudiante hace POST /pagos desde la app, el kiosco o la web | Activa el BFF correspondiente si app y kiosco piden representaciones distintas |
| 2 | El framework recibe la petición en su despachador único (DispatcherServlet en Spring, la instancia app o router en Express) | Front Controller |
| 3 | La petición atraviesa el pipeline de middlewares: autenticación, cupo de inscripción, bitácora | Chain of Responsibility, cada eslabón decide continuar o cortar |
| 4 | Llega a un controlador delgado (PagoController.registrarPago) que solo delega | Handler ligado a la ruta por el Front Controller, sin lógica de negocio |
| 5 | El controlador invoca a PagoService.registrarPago | Service Layer, orquesta el caso de uso |
| 6 | El servicio obtiene la política de cobro correcta según el medio elegido | Factory crea, Strategy ejecuta la política (tarjeta, SPEI, ventanilla) |
| 7 | La estrategia de pago llama al colaborador externo, cuyo protocolo (crédito, 00) hay que traducir al dominio (pago de inscripción, acreditado) | Adapter, anticorrupción |
| 8 | El servicio persiste el cobro y da de alta las materias en una sola operación atómica | Unit of Work |
| 9 | Al confirmarse el pago se dispara un evento PagoAcreditado que activa el correo y el aviso a caja, sin bloquear la transacción | Observer, en cola, no en proceso |
| 10 | Si el estudiante pulsa pagar dos veces mientras la página tarda, el segundo intento se detecta y no se cobra otra vez | Idempotency key sobre el recurso POST /pagos |

No se inventa ninguna capa que solo delegue, cada paso corresponde a una estructura que el esquema de composición ya contempla: borde, frontal, middleware, controlador delgado, capa de servicio, integración, datos y notificación.
