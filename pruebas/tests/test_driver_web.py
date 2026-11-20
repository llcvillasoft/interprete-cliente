from pathlib import Path

import pytest

from bateria.contrato import IdentificadorDesconocido
from bateria.driver.web import ElementoNoEncontrado, PantallaWeb

DOBLE = (Path(__file__).parent / "dobles" / "semantica_hoy.html").resolve()


@pytest.fixture
def pantalla(pagina):
    pagina.goto(DOBLE.as_uri())
    return PantallaWeb(pagina, espera_ms=300)


def test_un_identificador_fuera_del_contrato_no_se_localiza(pantalla):
    with pytest.raises(IdentificadorDesconocido):
        pantalla.elemento("hoy.boton.inventado")


def test_antes_de_activar_la_semantica_no_hay_elementos(pantalla):
    with pytest.raises(ElementoNoEncontrado, match="hoy.ventana.en-es"):
        pantalla.texto("hoy.ventana.en-es")


def test_activar_la_semantica_expone_los_identificadores(pantalla):
    pantalla.activar_semantica()
    assert "1,40" in pantalla.texto("hoy.ventana.en-es")


def test_cada_identificador_localiza_un_solo_elemento(pantalla):
    pantalla.activar_semantica()
    assert pantalla.elemento("hoy.ventana.es-en").count() == 1


def test_un_identificador_del_contrato_que_la_pantalla_no_muestra_falla_con_su_nombre(pantalla):
    pantalla.activar_semantica()
    with pytest.raises(ElementoNoEncontrado, match="hoy.navegacion.riel"):
        pantalla.texto("hoy.navegacion.riel")


def test_pulsar_un_identificador_dispara_su_accion(pantalla):
    pantalla.activar_semantica()
    pantalla.pulsar("hoy.practicar.boton")
    assert "iniciada" in pantalla.texto("hoy.practicar.boton")


def test_activar_la_semantica_espera_al_marcador_que_llega_tarde(pagina):
    pagina.set_content(
        """
        <html><body><script>
          setTimeout(() => {
            const marcador = document.createElement('flt-semantics-placeholder');
            marcador.addEventListener('click', () => {
              const nodo = document.createElement('flt-semantics');
              nodo.setAttribute('flt-semantics-identifier', 'hoy.practicar.boton');
              document.body.appendChild(nodo);
            });
            document.body.appendChild(marcador);
          }, 800);
        </script></body></html>
        """
    )
    pantalla = PantallaWeb(pagina, espera_ms=3000)
    pantalla.activar_semantica()
    assert pantalla.elemento("hoy.practicar.boton").count() == 1


def test_texto_usa_la_etiqueta_accesible_cuando_el_nodo_no_tiene_texto(pagina):
    pagina.set_content(
        """
        <html><body>
          <flt-semantics flt-semantics-identifier="hoy.navegacion.barra"
                         aria-label="Navegación inferior"></flt-semantics>
        </body></html>
        """
    )
    pantalla = PantallaWeb(pagina, espera_ms=1000)
    assert pantalla.texto("hoy.navegacion.barra") == "Navegación inferior"
