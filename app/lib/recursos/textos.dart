/// Textos visibles de la app, en un solo lugar.
///
/// La capa de presentación los toma de aquí: cambiarlos o traducirlos no toca los
/// widgets. Las cadenas con datos son funciones, para que el dato entre sin concatenar
/// en la pantalla.
abstract final class Textos {
  static const practicar = 'Practicar';
  static const revisar = 'Revisar';
  static const progreso = 'Progreso';
  static const cuaderno = 'Cuaderno';
  static const perfil = 'Perfil';
  static const hoy = 'Hoy';
  static const vistaPendiente = 'Esta vista llega en una fase posterior';
  static const navegacionInferior = 'Navegación inferior';
  static const navegacionLateral = 'Navegación lateral con etiquetas';

  static const sesionTitulo = 'Sesión de práctica';
  static const ventanaGrabacion = 'Ventana de grabación';
  static const estadoCreada = 'Lista para grabar';
  static const estadoGrabando = 'Grabando';
  static const estadoEnPausa = 'En pausa';
  static const estadoNoPrevisto = 'Estado no previsto';

  static String noSePudoCrearSesion(int estado) => 'No se pudo crear la sesión ($estado)';

  static String ventanaSinTurnos(String direccion) => '$direccion · sin turnos todavía';

  static String ventanaDetalle(String direccion, String factor, String tendencia) =>
      '$direccion · f $factor · $tendencia';
}
