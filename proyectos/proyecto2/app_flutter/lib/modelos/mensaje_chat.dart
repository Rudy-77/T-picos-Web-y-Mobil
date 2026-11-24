import 'respuesta_asistente.dart';

class MensajeChat {
  final String texto;
  final bool delComprador;
  final RespuestaAsistente? respuesta;
  // Si no es null, el mensaje es un error y guardo la pregunta para reintentarla.
  final String? preguntaFallida;

  const MensajeChat._(this.texto, this.delComprador, this.respuesta, this.preguntaFallida);

  factory MensajeChat.delComprador(String texto) => MensajeChat._(texto, true, null, null);

  factory MensajeChat.delAsistente(RespuestaAsistente respuesta) =>
      MensajeChat._(respuesta.respuesta, false, respuesta, null);

  factory MensajeChat.aviso(String texto) => MensajeChat._(texto, false, null, null);

  factory MensajeChat.error(String texto, String pregunta) =>
      MensajeChat._(texto, false, null, pregunta);

  bool get esError => preguntaFallida != null;
}
