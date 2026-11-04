# EXAMEN — MICROSERVICIOS, GATEWAY Y EL MONOLITO CON API

**Tópicos Selectos de Tecnologías Web y Móvil** · Eduardo Alcaraz

Nombre:\_\_\_\_\_\_\_\_Paulo Cesar Perez Martinez\_\_\_\_\_\_\_\_\_\_\_ Calificación :\_\_\_\_\_\_\_\_\_

## Indicaciones

Este examen *no* se aprueba de memoria. Casi todas las preguntas
tienen una respuesta que «suena bien» y está mal, o dos opciones
defendibles donde se califica el argumento.

Reglas:

- Expliquen el *porqué*. Una conclusión sin razonamiento vale la mitad
(o menos).
- Cuando digan «depende», digan *de qué*.
- No hace falta código que compile; sí hace falta que el diseño cierre
(quién llama a quién, qué pasa si algo falla, qué ve el cliente).
- Pueden dibujar. Un dibujo contradictorio con el texto resta.

Puntaje: *100 puntos* (10 × 10).

## 1 — La frase del compañero (10 puntos)

En el pizarrón quedó:

> La API separa clientes del servidor; los microservicios
> separan servidores entre sí.

Un compañero dice: «Entonces, si mi monolito Django expone una API y
además lo meto en Docker, ya cumplí las dos mitades de la frase.»

> **a)** Desarmen su argumento. ¿Qué parte de la frase cree cumplir con la
> API? ¿Qué parte cree cumplir con Docker? ¿En qué se equivoca en cada
> una?

**R:** Con la API cree cumplir la primera mitad de la frase (separar clientes del servidor) y con Docker cree cumplir la segunda (separar servidores entre sí). La primera sí se cumple, pero la segunda no.

Porque API es como un contrato entre el que la usa y el que da el servicio. Dice cómo se le habla al servidor, pero no cuántos servidores hay. Su Django sigue siendo un solo servidor por dentro, así que con la API solo se cumple la mitad.

Por otro lado usa Docker para meter el monolito en un contenedor solo lo deja en una caja. Sigue habiendo una sola unidad de despliegue, una sola base de datos y un solo proceso lógico. Para separar servidores entre sí hacen falta dos piezas con responsabilidades distintas que se puedan desplegar y fallar de forma independiente.

En resumen, confundió herramienta con diseño: Docker empaqueta, pero no decide dónde se corta el sistema.

> **b)** Den un contraejemplo mínimo: mismo código Django, *con* API y *con*
> Docker, que *sigamos* pudiendo llamar monolito. ¿Qué tendría que
> añadir (o partir) para que deje de serlo?

**R:** Un proyecto Django con tres apps (usuarios, pedidos, recomendar), expuesto por REST, en un solo Dockerfile y con una misma base de datos. Tiene API y tiene Docker, pero sigue siendo monolito:

Se despliega todo junto: un cambio en "recomendar" obliga a reconstruir y reiniciar "pedidos".

Si se cae el proceso, falla todo.

Comparten la base de datos y el código, y se llaman con un import.

Aunque lo corriera en varias réplicas iguales detrás de un balanceador, seguiría siendo el mismo programa copiado varias veces.

Para dejar de serlo habría que partirlo, por ejemplo, en "pedidos" y "recomendar" como dos servicios en contenedores distintos, con despliegues independientes y que se comuniquen por red y no por import.

Lo esencial es el límite de proceso/despliegue: que uno se pueda caer o actualizar sin tumbar al otro.

> **c)** ¿La frase del pizarrón habla de *tecnologías* (Docker, REST) o de
> *límites de proceso / despliegue*? Defiendan su lectura con lo que
> vieron en clase.

**R:** La frase habla de límites de proceso y despliegue, no de tecnología. "API" y "microservicios" describen dónde está la frontera (cliente/servidor o servidor/servidor); Docker y REST son solo herramientas posibles para implementarla.

Como en la actividad "Monolito con API frente a microservicios": la plataforma de entregas tiene API y corre en Docker, con nginx y tres copias de la misma imagen (gunicorn) más Postgres. Aun así la clasificamos como monolito con API, porque en views.py la vista "recomendar" llama a obtener_recomendador().sugerir(paquete) con un import, dentro del mismo proceso y sin red de por medio.

Con más réplicas, más contenedores o más rutas, seguía siendo monolito. Para que fueran microservicios, el recomendador tendría que correr como otro servicio y hablarse por red, de modo que si el modelo no responde el envío no tenga por qué cancelarse.

Se puede hacer lo uno sin lo otro: microservicios sin Docker (procesos o máquinas separadas que se hablan por HTTP) y Docker sin microservicios (el monolito de la parte b).

Lo que cambia es cómo se despliega, escala y falla cada pieza, y eso depende de dónde se pone el corte, no de la herramienta.

## 2 — Tres rutas, una trampa (10 puntos)

El equipo muestra este `urls.py` de un solo proyecto Django:

```
path("usuarios/", ...),
path("pedidos/", ...),
path("recomendar/", ...),
```

y este `docker-compose.yml`:

```
services:
  api:
    build: .
    ports: ["8000:8000"]
    deploy:
      replicas: 3
```

Afirman: «Tres rutas + tres réplicas = microservicios con alta
disponibilidad.»

> **a)** Separen las dos ideas que mezclaron (rutas vs réplicas). ¿Qué
> problema resuelve cada una y cuál *no* resuelve?

**R:**

- Rutas: separar en rutas ayuda a organizar la aplicación por dentro. Resuelve orden y claridad, pero no separa nada en ejecución, porque las tres rutas viven en el mismo proyecto Django, en el mismo proceso y en el mismo despliegue. No resuelve ni disponibilidad ni independencia.
- Réplicas: son varias copias idénticas del mismo servicio. Resuelven disponibilidad y carga (si una copia cae, otra puede atender en su lugar), pero no resuelven la separación de responsabilidades, ya que tres réplicas de un monolito son un monolito.
- Hacer "tres rutas + tres réplicas" suma dos cosas que no son microservicios. Una organiza el código y la otra lo copia. Ninguna lo divide en piezas que se desplieguen y fallen por separado.

> **b)** Si una de las tres réplicas se cae a mitad de un `POST /pedidos`,
> ¿el sistema dejó de ser monolito? ¿Por qué sí o por qué no?

**R:** No, no dejó de ser monolito, y tampoco se volvió microservicios.

- Las tres réplicas ejecutan el mismo código, y todas incluyen usuarios, pedidos y recomendar.
- Que una réplica caiga es un problema de disponibilidad, no de arquitectura. El corte entre responsabilidades no cambió.
- Esa petición se pierde o falla y el cliente tiene que reintentar. Que el pedido quede a medias o no depende de si la escritura fue atómica.
- Lo que sí evitan las réplicas es que todo el sistema se caiga.

> **c)** Rediseñen *solo con palabras* el `compose` para que sí ilustre
> microservicios (nombres de servicios y responsabilidades; no hace
> falta YAML perfecto). ¿Cuántas *imágenes distintas* mínimo y por qué
> esa cantidad?

**R:** En el compose habría un servicio por responsabilidad, en lugar de un solo `api` copiado tres veces:

- gateway: único punto de entrada hacia afuera. Recibe las peticiones del cliente y las manda al servicio correcto. No tiene lógica de negocio. Es el único que publica un puerto al exterior (así también se evita el choque de puertos al tener réplicas).
- usuarios: altas, login y datos de usuario.
- pedidos: crear y consultar pedidos. Si necesita elegir el medio de envío, llama al servicio de recomendar por red.
- recomendar: sugiere el medio de transporte con el modelo `.joblib`.

Imágenes distintas mínimo: 3 construidas por nosotros (usuarios, pedidos, recomendar), más el gateway, que normalmente usa una imagen ya hecha (nginx), así que son 4 en total contando todas las del compose. Cada servicio tiene un código distinto, así que no pueden compartir imagen; si dos compartieran, seguirían siendo el mismo programa. Las réplicas de un mismo servicio sí pueden compartir su imagen, porque son copias del mismo código.

Nota: con un `ports: ["8000:8000"]` y 3 réplicas del mismo servicio, en un Compose normal suelen chocar por el puerto. En la práctica hace falta un balanceador como el nginx de la actividad de arquitectura.

## 3 — El gateway que «hace de más» (10 puntos)

Les proponen este diseño «para no complicar»:

> Un solo contenedor nginx+Python que: valida el JWT, elige
> el medio con el `.joblib`, guarda el pedido en SQLite,
> manda el correo y devuelve el HTML.

Lo llaman «API Gateway».

> **a)** ¿Es un gateway? Si no, ¿qué es? Usen la analogía del recepcionista
> (o otra) y digan qué oficios mezclaron.

**R:** No. Es un monolito con nginx pegado: un contenedor que hace de todo.

Un gateway es como un recepcionista: recibe, identifica a quien llega y lo dirige a donde va. No hace la contabilidad, no cocina, no manda las cartas.

Mezclaron cinco oficios: seguridad en el borde (validar el JWT), lógica de negocio/ML (elegir el medio con el modelo), datos (guardar el pedido), notificación (mandar el correo) y presentación (devolver el HTML).

> **b)** Mencionen *tres* consecuencias malas de ese diseño cuando el modelo
> pesado se reentrena cada semana y el correo empieza a fallar.

**R:**

1. Redespliegue de todo por un cambio del modelo: reentrenar obliga a reconstruir y reiniciar el contenedor, así que se reinicia también la validación del JWT y la entrada de pedidos. El borde se cae por algo que no le corresponde.
2. Un fallo arrastra a los demás: si el correo falla o tarda y va en la misma petición, el pedido se queda esperando o se rompe. El modelo pesado además compite por CPU y memoria con el borde.
3. No se puede replicar bien: SQLite vive dentro del contenedor, así que al redesplegar se pierden o se desincronizan los datos, y varias réplicas tendrían bases distintas.

> **c)** Partan ese contenedor en piezas. Para cada pieza digan: ¿queda en
> el borde (gateway) o detrás? No inventen diez servicios: el mínimo que
> separe borde, logística e (si hace falta) aviso.

**R:**

- Gateway (borde): se encarga de validar JWT, enrutar, rate limit y entregar el HTML/estáticos. Sin lógica de negocio.
- Logística/pedidos (detrás): elige el medio con el modelo y guarda el pedido en su propia base (mejor Postgres que SQLite). Es el que se reentrena y se despliega por separado.
- Aviso (detrás, solo si hace falta): manda el correo, de forma asíncrona, para que si falla no tumbe el pedido.

Por qué ese corte: separa por razón de cambio y de fallo. El borde cambia poco y debe estar siempre arriba; la logística cambia con el modelo; el aviso es opcional y puede fallar sin afectar.

## 4 — `localhost`, la trampa favorita (10 puntos)

Pedidos corre en un contenedor. Recomendar en otro, misma Compose.
Alguien «arregla» la conexión así:

```
RECOMENDAR_URL=http://127.0.0.1:8002
```

En su laptop, *sin* Docker, ese `curl` a `127.0.0.1:8002` sí
funcionaba.

> **a)** Expliquen por qué en Compose ese arreglo suele fallar *aunque*
> Recomendar esté sano. ¿A qué proceso apunta `127.0.0.1` desde dentro
> de Pedidos?

**R:** Cada contenedor tiene su propia red, así que `127.0.0.1` dentro de Pedidos apunta al propio contenedor de Pedidos.

Pedidos busca el puerto 8002 en sí mismo y ahí no corre nada, por eso la conexión es rechazada aunque Recomendar esté sano en otro contenedor.

En la laptop sin Docker funcionaba porque ambos procesos compartían la misma máquina.

> **b)** ¿Por qué `http://recomendar:8002` sí tiene chance de funcionar?
> ¿Quién «inventa» el nombre `recomendar`?

**R:** El nombre lo "inventa" Compose: toma el nombre del servicio en el docker-compose.yml y el DNS interno de Docker lo resuelve a la IP del contenedor.

Tiene chance (no es garantía) si:

- están en la misma red de Compose,
- el servicio se llama así, y
- el puerto es el que escucha dentro del contenedor.

> **c)** Ahora Recomendar se muda a la laptop de otro alumno
> (`192.168.0.57`). Escriban la URL que pondrían *y* dos cosas que
> tienen que ser verdad en la WiFi para que no sea teatro (puertos,
> firewall, etc.). Si solo cambian la URL y nada más, ¿qué puede seguir
> fallando?

**R:**

- La URL sería `http://192.168.0.57:8002`
- Las dos cosas que deben ser verdad en la WiFi:
  1. El servicio de Recomendar escucha en `0.0.0.0` (no solo en `127.0.0.1`) y el puerto 8002 está publicado en esa laptop.
  2. El firewall de esa laptop permite la entrada al 8002, y la WiFi no aísla a los clientes.
- Si solo se cambiara la URL, puede seguir fallando: el firewall, el aislamiento del AP, que la IP cambie por DHCP, que el servicio solo escuche en localhost, y en Django el `ALLOWED_HOSTS` (rechaza un Host que no esté permitido, con error 400).

## 5 — Fallo parcial con números (10 puntos)

Escenario medido en laboratorio (inventado pero coherente):

- 1000 `POST /pedidos` por hora en promedio.
- Recomendar tarda 200 ms cuando está bien.
- El 5 % del tiempo Recomendar no responde (timeout 3 s).
- Pedidos, si hay timeout, usa plan B (moto) y responde 200 en 50 ms.
- El gateway añade 5 ms.

> **a)** En la hora «normal» (Recomendar bien), ¿el cliente espera ~200 ms o
> ~3 s? ¿Quién pone el tiempo dominante?

**R:** El cliente espera ~200 ms, no ~3 s. El tiempo dominante lo pone Recomendar (200 ms); los 3 s solo pesan cuando Recomendar no responde.

> **b)** En el 5 % malo, con plan B: ¿el cliente ve error o pedido creado?
> ¿Qué «mentira útil» están aceptando (medio quizá no óptimo)?

**R:** El cliente no ve un error, ve un "pedido creado", pero espera ~3 s antes (el timeout) + 50 ms.

La "mentira útil" es que se acepta un medio que quizá no es el óptimo para no fallar: se prioriza la disponibilidad sobre la optimización.

> **c)** Un compañero dice: «Mejor que Pedidos *reintente* 10 veces hasta
> que Recomendar vuelva; así nunca usamos plan B.» ¿Qué le pasa a la
> cola de peticiones y al gateway si Recomendar está caído 10 minutos?
> ¿Plan B siempre es peor que reintentar? Argumenten.

**R:** Es mala idea si Recomendar cae 10 minutos:

- Cada petición se queda hasta 10 × 3 s = 30 s ocupando un worker/conexión. Con ~1000 pedidos/h (≈0.28/s) hay ~8 peticiones atascadas a la vez en régimen estable.
- Con pocos workers se agotan, la cola crece, el gateway empieza a dar timeouts propios (504) y el cliente ve error.
- Además, al volver Recomendar recibe una avalancha de reintentos acumulados.

El plan B no siempre es peor: depende de qué cuesta un medio no óptimo vs. una espera o un error. Si una mala recomendación es grave (carga delicada, no hay medio alternativo válido), conviene fallar o esperar; si no, el plan B es mejor. Lo sensato: pocos reintentos con espera creciente, un corte tipo "circuit breaker" y plan B.

## 6 — Apagan el «edificio equivocado» (10 puntos)

Tres contenedores: gateway, pedidos, recomendar. Hacen tres
experimentos *por separado*:

1. `docker compose stop gateway`
2. `docker compose stop pedidos`
3. `docker compose stop recomendar`

Para *cada* experimento digan qué ve el navegador en `http://IP:8080/`
(página / crear pedido) y qué sigue vivo por dentro. No basta «no
jala»: digan *qué* no jala y qué sí podría seguir respondiendo si
alguien hablara por dentro de la red.

Luego: ¿en cuál de los tres el sistema «parece» más muerto hacia
afuera aunque más piezas sigan arriba? ¿Qué les enseña eso del borde?

**R:** Supuesto: el gateway sirve el HTML y es el único expuesto en `http://IP:8080/`.

1. `stop gateway`
   - Navegador: nada, no carga la página ni se puede crear pedido (conexión rechazada).
   - Vivo por dentro: pedidos y recomendar siguen sanos; si alguien les hablara directo por la red interna, responderían.
2. `stop pedidos`
   - Navegador: la página carga (la sirve el gateway), pero crear pedido falla (error 502/503 desde el gateway).
   - Vivo por dentro: gateway y recomendar siguen vivos; recomendar aún podría responder sugerencias.
3. `stop recomendar`
   - Navegador: la página carga y crear pedido puede funcionar con plan B (si pedidos tiene timeout y plan B); sin plan B, daría error.
   - Vivo por dentro: gateway y pedidos siguen vivos.

¿Cuál parece más muerto hacia afuera? El 1 (gateway), aunque ahí es donde más piezas siguen arriba.

Qué enseña del borde: que es la "puerta única": si cae, el sistema parece muerto aunque por dentro todo funcione. Por eso el borde debe ser delgado, simple, vigilado y con réplicas/balanceador, y ahí no se mete lógica de negocio.

## 7 — WiFi del salón, conflicto de roles (10 puntos)

Cuatro alumnos:

- Ana: gateway + HTML
- Beto: pedidos
- Carla: recomendar
- Diana: «yo también levanté un gateway en mi laptop por si Ana falla»

Todos en la misma WiFi. El cliente (otro equipo) configura a veces la
IP de Ana y a veces la de Diana.

> **a)** ¿Qué problema de *diseño* introdujo Diana aunque «todo responda
> 200»? (Piensen en una sola puerta vs dos puertas.)

**R:** Pasó de una sola puerta a dos puertas. Dos gateways pueden tener configuración, reglas de autenticación, versiones y logs distintos.

- El cliente no sabe cuál es la fuente de verdad, y los límites y sesiones se parten.
- No es un failover real, porque cambiarse a mano de IP no es alta disponibilidad.

Un respaldo de verdad necesita una sola dirección estable (balanceador/VIP/DNS) detrás de la cual haya varias instancias idénticas. Que todo responda 200 no significa que el diseño sea correcto.

> **b)** Beto configuró `RECOMENDAR_URL=http://localhost:8002` porque en su
> máquina desarrolló Pedidos y Recomendar juntos. En el salón Recomendar
> está en la laptop de Carla. ¿Qué falla y cómo lo corrigen *sin* juntar
> otra vez los dos servicios en la laptop de Beto?

**R:** Falla porque `localhost` en la laptop de Beto apunta a la propia laptop de Beto, donde ya no corre Recomendar, y la conexión es rechazada.

Para corregirlo sin juntar los servicios: poner la URL de la laptop de Carla (`http://IP_DE_CARLA:8002`) como variable de entorno, y que Carla escuche en `0.0.0.0` con el firewall permitiendo el 8002.

> **c)** La WiFi del campus aísla clientes («AP isolation»). `ping` entre
> alumnos falla. ¿Pueden hacer la práctica tal cual? Si no, propongan
> *un* plan B de laboratorio que preserve la lección «procesos
> separados» (aunque no sea WiFi del salón).

**R:** No, tal cual no se puede: si el AP aísla clientes, las laptops no se ven entre sí.

Plan B: levantar los tres servicios en una sola laptop con Docker Compose, en contenedores separados. Conserva la lección: son procesos separados que se hablan por red (`http://recomendar:8002`), aunque no sea la WiFi del salón.

## 8 — El front que conoce demasiado (10 puntos)

El HTML hace esto al enviar el formulario:

```
await fetch("http://192.168.1.20:8002/sugerir", { ... }); // Recomendar
await fetch("http://192.168.1.30:8001/pedidos", { ... }); // Pedidos
```

El autor dice: «Más rápido: me salto el gateway.»

> **a)** Listen *tres* problemas (seguridad, cambio de IP, orden de
> llamadas, consistencia del folio, CORS, etc.).

**R:**

1. Seguridad: el navegador queda conociendo y llamando IPs y puertos internos; sin autenticación ni rate limit centralizados, cualquiera podría llamar directo a Recomendar o a Pedidos.
2. Acoplamiento a IPs: si cambia una IP (192.168.1.20 o 192.168.1.30), se rompe el front; además esas IPs privadas ni siquiera son alcanzables desde fuera de la red.
3. Orden y consistencia: son dos llamadas no atómicas hechas por el cliente. Si la segunda falla, queda un estado a medias; y el front tendría que manejar timeouts y plan B.

> **b)** Rediseñen la secuencia correcta con gateway: *una* llamada desde el
> navegador. ¿Quién habla con Recomendar y por qué no el navegador?

**R:**

1. El navegador hace una sola llamada: `POST /pedidos` al gateway.
2. El gateway valida (JWT, rate limit) y la enruta a Pedidos.
3. Pedidos llama a Recomendar (con timeout y plan B).
4. Pedidos guarda el pedido y crea el folio.
5. La respuesta vuelve por el gateway al navegador.

¿Por qué no el navegador con Recomendar? Porque Recomendar es un detalle interno: el front no debe conocer la topología, exponerlo abre seguridad y CORS, y el manejo de fallos (timeout/plan B) es lógica del servidor.

> **c)** El selector de modelo (`arbol=|=bosque=|=red`) va en el JSON. Si el
> front llama directo a Recomendar *y* a Pedidos, ¿quién debería crear
> el folio para no duplicar lógica? ¿Qué invariante rompen si los dos
> «crean» algo?

**R:** El folio debe crearlo Pedidos, una sola vez, porque Pedidos es el dueño del pedido.

El selector (arbol|bosque|red) viaja en el JSON: gateway → Pedidos → se pasa a Recomendar como parámetro.

Invariante que se rompe si dos "crean": el folio deja de ser único y de tener una sola fuente de verdad.

## 9 — El LLM vendedor (10 puntos)

Producto: tienda + envíos.

- Modelo `.joblib`: medio de transporte.
- LLM: texto para convencer al cliente en la ficha del producto.

Un arquitecto propone *un solo* microservicio `cerebro` que: recibe el
carrito, elige el medio con el árbol *y* genera el pitch de ventas con
el LLM, todo en la misma petición `/inteligente`.

> **a)** Critiquen el nombre y el corte. ¿Qué dos oficios distintos
> mezclaron? ¿Qué falla cuando el LLM tarda 8 s y el despacho necesita
> responder en < 500 ms?

**R:**

- Nombre: `cerebro` es vago, un "servicio-dios" que acumula responsabilidades.
- Oficios mezclados: (1) decisión logística (elegir el medio): rápida y crítica para el despacho; (2) texto de ventas (el pitch del LLM): lento y no crítico.
- Qué falla si el LLM tarda 8 s y el despacho necesita < 500 ms: como todo va en la misma petición `/inteligente`, el despacho espera los 8 s y se incumple el tiempo. Un fallo o caída del LLM tumbaría también el envío. Y escalan distinto (GPU vs CPU).

> **b)** Propongan dos endpoints (o dos servicios) y digan cuál usa el
> *front de tienda* y cuál el *flujo de pedido/envío*.

**R:**

- `/recomendar-envio` (modelo .joblib): lo usa el flujo de pedido/envío.
- `/pitch` (LLM): lo usa el front de tienda en la ficha del producto, con timeout, caché y un texto genérico como plan B si el LLM no responde.

> **c)** El LLM vive en un server con GPU en otra red. El front de tienda
> ¿apunta a la GPU o al gateway? Si mañana cambian de proveedor LLM
> (otro host), ¿qué archivo/config quieren tocar *una sola vez*?

**R:** El front de tienda apunta al gateway, no a la GPU, porque así el front no conoce al proveedor ni la red del LLM.

Si mañana cambia el proveedor, se toca un solo lugar: la configuración del gateway (el upstream de la ruta `/pitch`) o la variable de entorno del servicio de pitch (`LLM_URL`).

## 10 — El inversionista y la semana imposible (10 puntos)

Hoy:

- Panel interno: monolito Django (funciona, poco tráfico).
- App clientes: gateway + pedidos + recomendar.
- Idea: LLM de ventas (aún no).
- Equipo: 5 personas.
- Inversionista: «Todo a microservicios en 7 días, incluido el panel,
o no hay dinero.»

> **a)** Escriban la respuesta al inversionista (máx. 8 líneas) con postura
> *y* riesgo concreto si obedecen a ciegas.

**R:** No recomendamos partir el panel en 7 días.

El panel funciona y tiene poco tráfico; partirlo en servicios no mejora nada que hoy duela.

Con 5 personas, seis servicios nuevos significan operar más despliegues, más red y más datos compartidos, justo en una semana.

El riesgo concreto si obedecemos a ciegas: rompemos el panel que hoy funciona y dejamos sin hacer lo que sí es riesgoso (seguridad del gateway público y el reentrenamiento que puede tumbar Pedidos).

Proponemos priorizar esta semana lo urgente, y partir el panel por etapas cuando una métrica lo justifique.

> **b)** Ordenen *estas cuatro* iniciativas de más a menos urgente para
> *esta* semana y justifiquen el orden (no el catálogo soñado):

**R:** Orden de más a menos urgente:

1. Auth + rate limit en el gateway público (iniciativa 3): es la puerta expuesta a internet; sin esto cualquiera abusa del sistema. Es lo más urgente y de poco costo.
2. Sacar el reentrenamiento a un pipeline aparte (iniciativa 2): hoy un reentrenamiento semanal puede tumbar Pedidos, o sea el negocio real.
3. Partir el panel en 6 microservicios (iniciativa 1): no es urgente, funciona y tiene poco tráfico. Es mucho trabajo y riesgo para poco beneficio.
4. Subir el LLM sin timeouts ni plan B (iniciativa 4): último, y no debería hacerse así. El LLM aún no existe, y subirlo sin timeouts ni plan B es pedir fallos; hay que esperar a tener ambos.

> **c)** Inventen *una* métrica que les diga «ya toca partir X del monolito»
> (no «porque está de moda»). Tiene que ser observable (tiempo, errores,
> despliegues, equipo…).

**R:** Partimos X cuando más del 30 % de los despliegues del monolito se retrasan o se revierten por cambios de X durante cuatro semanas seguidas.

> **d)** Cierren con una frase propia (no copien el apunte) que capture:
> ¿microservicios son el objetivo o la herramienta?

**R:** Los microservicios son una herramienta, no el objetivo: solo valen la pena cuando el crecimiento del sistema o del equipo trae un problema concreto (desplegar, escalar o fallar por separado); migrar solo por moda nada más complica el sistema.
