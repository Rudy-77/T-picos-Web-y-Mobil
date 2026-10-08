# Lenguajes, Paradigmas y Patrones de Diseño

Investigación de 20 lenguajes de programación y frameworks: su paradigma dominante, el/los patrón(es) de diseño que más se asocian a su uso, y un análisis final sobre qué paradigmas tienden a generar problemas de diseño.

---

## 1. Tabla resumen

| # | Lenguaje / Framework | Paradigma(s) | Patrón(es) de diseño asociado |
|---|----------------------|--------------|--------------------------------|
| 1 | **Java** | Orientado a objetos | Singleton, Factory, Observer |
| 2 | **Python** | Multiparadigma (OOP, funcional, procedural) | Decorator, Iterator |
| 3 | **JavaScript** | Multiparadigma (prototipos, funcional, event-driven) | Observer / Pub-Sub, Module |
| 4 | **C++** | OOP + procedural + genérico | RAII, Factory, Template Method |
| 5 | **C** | Procedural | Pipeline (pipes and filters) |
| 6 | **C#** | OOP + funcional (LINQ) | Repository, Dependency Injection |
| 7 | **Ruby** | Orientado a objetos puro | Metaprogramming / DSL |
| 8 | **Ruby on Rails** (framework) | MVC | Active Record |
| 9 | **Haskell** | Funcional puro | Monad, Functor |
| 10 | **Erlang** | Funcional + concurrente (actores) | Actor, Supervisor Tree |
| 11 | **Prolog** | Lógico / declarativo | Rule-based (reglas y hechos) |
| 12 | **Go** | Procedural + concurrente, composición | Worker Pool, Interface (composición) |
| 13 | **Rust** | Multiparadigma (sistemas + funcional) | Ownership/RAII, Strategy (traits) |
| 14 | **Swift** | OOP + funcional (protocol-oriented) | Delegate, Protocol-Oriented |
| 15 | **Kotlin** | OOP + funcional | Extension Functions, Null Object |
| 16 | **PHP** | Procedural + OOP | Singleton, MVC (vía frameworks) |
| 17 | **Laravel** (framework, PHP) | MVC | Facade, Service Container (DI) |
| 18 | **Scala** | Funcional + OOP (híbrido) | Monad, Actor (Akka) |
| 19 | **Angular** (framework, TS) | Componentes + MVVM | Dependency Injection, Observer (RxJS) |
| 20 | **React** (framework, JS) | Declarativo + basado en componentes | Composition, Flux/Redux |

---

## 2. Detalle por lenguaje/framework

### Orientados a objetos
- **Java**: todo gira en torno a clases y objetos. El ecosistema (especialmente Spring) popularizó patrones como *Singleton*, *Factory* y *Dependency Injection*.
- **C++**: OOP combinado con manejo manual de memoria; el patrón *RAII* (Resource Acquisition Is Initialization) es casi obligatorio para evitar fugas de memoria.
- **C#**: similar a Java pero con fuerte integración funcional (LINQ). Muy común en arquitecturas empresariales con *Repository* y *DI*.
- **Ruby**: "todo es un objeto". Su flexibilidad sintáctica fomenta *metaprogramación* y *DSLs* (lenguajes específicos de dominio).
- **Swift**: introduce el enfoque *protocol-oriented*, una alternativa a la herencia clásica.
- **Kotlin**: OOP moderno con null-safety incorporada, reduce errores comunes de Java.

### Multiparadigma
- **Python**: permite OOP, funcional y procedural en el mismo proyecto; *Decorator* es nativo del lenguaje (`@decorator`).
- **JavaScript**: basado en prototipos (no clases reales hasta ES6), con fuerte enfoque event-driven; el patrón *Observer* es la base de casi toda la reactividad web.
- **Scala**: corre sobre la JVM combinando OOP y funcional puro; muy usado junto con el modelo de actores (Akka).
- **Rust**: sin herencia clásica; usa *traits* (similares a interfaces) para lograr polimorfismo, y su sistema de *ownership* resuelve la gestión de memoria sin recolector de basura.

### Funcionales
- **Haskell**: paradigma funcional puro, sin efectos secundarios directos. Usa *Monads* para modelar operaciones con estado o I/O.
- **Erlang**: funcional, pero su fortaleza es la concurrencia mediante el *modelo de actores* y árboles de supervisión para tolerancia a fallos.

### Lógico / declarativo
- **Prolog**: se programa mediante hechos y reglas; el "patrón" no es de diseño clásico sino de resolución por *backtracking*.

### Procedurales
- **C**: sin objetos, todo se organiza en funciones y estructuras de datos. El patrón más natural es *Pipeline* (procesar datos en etapas).
- **Go**: procedural con concurrencia nativa (goroutines/channels); favorece composición sobre herencia y el patrón *Worker Pool* para tareas concurrentes.
- **PHP**: procedural en su origen, hoy híbrido con OOP; su uso más común es a través de frameworks MVC.

### Frameworks (heredan paradigma del lenguaje base + patrón arquitectónico propio)
- **Ruby on Rails**: MVC + *Active Record* (mapea tablas de BD a objetos).
- **Laravel**: MVC + *Service Container* para inyección de dependencias + *Facade* para simplificar acceso a servicios.
- **Angular**: arquitectura de componentes con *Dependency Injection* nativa y *Observer* vía RxJS para manejar flujos de datos asíncronos.
- **React**: no impone MVC; se basa en *composición de componentes* y patrones de manejo de estado como *Flux/Redux*.

---

## 3. Análisis: paradigmas que generan problemas

No es el lenguaje en sí el que causa problemas, sino cómo su paradigma predominante **empuja** a ciertas decisiones de diseño. Algunos ejemplos:

### 3.1 Orientado a objetos — sobre-ingeniería y jerarquías frágiles
Lenguajes como **Java** y **C++** facilitan (y a veces fomentan) jerarquías de herencia muy profundas. Esto produce el llamado **"fragile base class problem"**: un cambio en una clase base puede romper silenciosamente a todas sus subclases. También es común el antipatrón **God Object**, donde una clase termina acumulando demasiadas responsabilidades por "encajar" todo en el modelo de objetos.

### 3.2 Procedural sin encapsulación — estado global y código espagueti
**C** y el **PHP** más antiguo (pre-frameworks) no obligan a encapsular datos. Es fácil terminar con variables globales compartidas entre funciones, lo que genera efectos secundarios difíciles de rastrear y dificulta las pruebas unitarias.

### 3.3 JavaScript — el problema del "callback hell" y el `this`
El modelo basado en prototipos y el manejo asíncrono por callbacks generó históricamente código muy anidado y difícil de leer ("callback hell"), parcialmente resuelto con Promises y `async/await`. Además, el valor de `this` cambia según cómo se llama a una función, una fuente constante de errores para quienes vienen de OOP clásico.

### 3.4 Funcional puro — curva de aprendizaje y manejo de efectos
**Haskell** obliga a modelar cualquier efecto secundario (leer un archivo, imprimir en pantalla) mediante *Monads*. Es matemáticamente elegante, pero representa una barrera de entrada alta y dificulta la adopción en equipos sin formación funcional previa.

### 3.5 Lógico — comportamiento impredecible
En **Prolog**, el motor de resolución por *backtracking* puede volverse muy costoso computacionalmente sin que el desarrollador tenga control explícito sobre el orden de evaluación, lo que complica la depuración y la predicción de rendimiento.

### 3.6 Concurrencia explícita — fatiga en el manejo de errores
**Go** decidió no usar excepciones y en su lugar retorna errores como valores. Esto da control y previsibilidad, pero en la práctica genera código repetitivo (`if err != nil` en cada línea), un costo de legibilidad que varios desarrolladores señalan como incómodo a gran escala.

### 3.7 Multiparadigma — inconsistencia de estilo
Lenguajes flexibles como **Python**, **C#** o **Scala** permiten mezclar OOP y funcional libremente. Sin convenciones de equipo claras, esto deriva en bases de código inconsistentes, donde cada desarrollador resuelve el mismo problema con un estilo distinto, dificultando el mantenimiento a largo plazo.

---

## 4. Conclusión

No existe un paradigma "perfecto": cada uno resuelve bien un tipo de problema y traslada complejidad hacia otro lugar.

- **OOP** ordena el dominio del problema, pero puede sobre-modelar relaciones simples.
- **Procedural** es simple y directo, pero no escala bien sin disciplina de encapsulación.
- **Funcional** favorece la predictibilidad y el testing, a costa de una curva de aprendizaje mayor.
- **Concurrente/actores** (Erlang, Go) resuelve bien la tolerancia a fallos, pero introduce nuevos modelos mentales.
- **Multiparadigma** da libertad, pero exige convenciones de equipo para no perder consistencia.

La elección de lenguaje o framework, entonces, no debería basarse solo en el paradigma que promueve, sino en qué tan bien ese paradigma se alinea con el problema que se está resolviendo y con la disciplina del equipo que lo va a mantener.
