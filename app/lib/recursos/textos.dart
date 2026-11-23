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

  static const estadoEnvio = 'Estado del envío';
  static const sinSincronizar = 'Todavía no se ha sincronizado';
  static const ultimaSincronizacionCompleta = 'Última sincronización completa';
  static const ultimaSincronizacionIncompleta = 'Última sincronización incompleta';

  static String enviosPendientes(int cantidad) => 'Eventos pendientes: $cantidad';

  static String enviosRechazados(int cantidad) => 'Eventos rechazados: $cantidad';

  static String noSePudoCrearSesion(int estado) => 'No se pudo crear la sesión ($estado)';

  static String ventanaSinTurnos(String direccion) => '$direccion · sin turnos todavía';

  static String ventanaDetalle(String direccion, String factor, String tendencia) =>
      '$direccion · f $factor · $tendencia';

  static const ajustesTitulo = 'Ajustes y privacidad';
  static const consentimientosTitulo = 'Consentimientos';
  static const consentimientosVacios = 'No hay consentimientos registrados.';
  static const consentimientoAudio = 'Guardar mi audio en el servidor';
  static const concedido = 'Sí';
  static const noConcedido = 'No';
  static const retencionTitulo = 'Cuánto se conserva';
  static const retencionAudio = 'El audio guardado se borra 30 días después de cada sesión.';
  static const retencionEventos =
      'Los eventos y tu expediente se conservan mientras exista tu cuenta.';
  static const datosTitulo = 'Tus datos';
  static const exportarDatos = 'Exportar mis datos';
  static const borrarCuenta = 'Borrar mi cuenta';
  static const borrarCuentaPregunta = '¿Borrar tu cuenta?';
  static const borrarCuentaAviso =
      'Se destruye la clave de datos de tu cuenta. Lo que está sellado con ella ya no se podrá leer.';
  static const confirmarBorrado = 'Sí, borrar';
  static const cancelar = 'Cancelar';
  static const errorAjustes = 'No se pudo completar la operación. Inténtalo de nuevo.';

  /// Nombre visible de un consentimiento; las claves sin nombre se muestran tal cual.
  static String etiquetaConsentimiento(String clave) =>
      clave == 'audio' ? consentimientoAudio : clave;

  static String exportacionLista(int flujos) => 'Exportación lista: $flujos flujos en el paquete.';

  static String cuentaBorrada(int sesiones) =>
      'Cuenta borrada. Se destruyó la clave y se borraron $sesiones sesiones.';
}
