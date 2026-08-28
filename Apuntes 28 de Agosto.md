# Problemas de Diseño de Software

## Problema 1: App de mensajería tipo WhatsApp usando LoRa

**Planteamiento:** ¿Qué lenguaje y qué patrón de diseño usarían para hacer una aplicación tipo WhatsApp que permita trabajar con LoRa?

**Idea base:** Una app de chat que, en vez de usar la línea celular, use un módulo LoRa conectado al celular para enviar y recibir mensajes.

### Tecnologías propuestas
- **Lenguaje de la app:** Flutter, para poder usar la misma base de código en ambas plataformas (Android e iOS).
- **Lenguaje del módulo:** C/C++, ya que es el lenguaje con el que típicamente se programan los módulos LoRa.

### Pasos básicos
1. Conectar el celular al módulo LoRa.
2. Escribir el mensaje en la app.
3. Enviarlo por LoRa al otro dispositivo.
4. Mostrarlo en pantalla cuando llegue.

### Patrón de diseño
**Observer**, para que la app se entere y muestre el mensaje apenas llegue.



## Problema 2: Detección de espacios libres en un estacionamiento con cámaras de seguridad

**Planteamiento:** Reconocer, con las cámaras de seguridad de una escuela, cuántos espacios vacíos hay en el estacionamiento para poder utilizarlos. ¿Qué tecnología, qué lenguaje y qué patrón de diseño se pueden utilizar? El objetivo es que el sistema indique cuántos lugares libres hay.

**Idea base:** Usar las cámaras ya existentes para "ver" cada espacio y detectar si hay un auto o no.

### Tecnologías propuestas
- **Lenguaje:** Python, por ser el más usado para este tipo de tareas.
- **Tecnología clave:** OpenCV para el procesamiento de imagen, combinado con un modelo simple de detección como YOLO o similar.

### Pasos básicos
1. Marcar en la imagen dónde está cada espacio.
2. Revisar cada espacio: ¿hay auto o no?
3. Contar los espacios que están vacíos.
4. Mostrar el número resultante.

### Patrón de diseño
**Pipeline**, para organizar el proceso en pasos simples y separados.
