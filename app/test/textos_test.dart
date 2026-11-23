import 'package:flutter_test/flutter_test.dart';
import 'package:interprete_cliente/recursos/textos.dart';

void main() {
  test('una ventana con turnos muestra la dirección, el factor y la tendencia', () {
    expect(
      Textos.ventanaDetalle('EN→ES', '1,40', 'al alza'),
      'EN→ES · f 1,40 · al alza',
    );
  });

  test('una dirección sin turnos lo dice', () {
    expect(Textos.ventanaSinTurnos('ES→EN'), 'ES→EN · sin turnos todavía');
  });

  test('un fallo al crear la sesión muestra el código de estado', () {
    expect(Textos.noSePudoCrearSesion(409), 'No se pudo crear la sesión (409)');
  });

  test('cada estado de la sesión tiene su etiqueta visible', () {
    expect(Textos.estadoCreada, 'Lista para grabar');
    expect(Textos.estadoGrabando, 'Grabando');
    expect(Textos.estadoEnPausa, 'En pausa');
    expect(Textos.estadoNoPrevisto, 'Estado no previsto');
  });

  test('los destinos de navegación tienen su etiqueta', () {
    expect(Textos.practicar, 'Practicar');
    expect(Textos.revisar, 'Revisar');
    expect(Textos.progreso, 'Progreso');
    expect(Textos.cuaderno, 'Cuaderno');
    expect(Textos.perfil, 'Perfil');
  });

  test('el consentimiento de audio se muestra con un nombre legible', () {
    expect(Textos.etiquetaConsentimiento('audio'), 'Guardar mi audio en el servidor');
  });

  test('un consentimiento sin nombre conocido se muestra con su clave', () {
    expect(Textos.etiquetaConsentimiento('marketing'), 'marketing');
  });

  test('la retención dice cuánto se conserva el audio y cuánto los eventos', () {
    expect(
      Textos.retencionAudio,
      'El audio guardado se borra 30 días después de cada sesión.',
    );
    expect(
      Textos.retencionEventos,
      'Los eventos y tu expediente se conservan mientras exista tu cuenta.',
    );
  });
}
