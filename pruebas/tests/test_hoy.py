"""Pasos de features/hoy.feature.

La app se indica con BATERIA_APP_URL. La API simulada escucha en BATERIA_API_PUERTO
(por defecto 8787), que la compilación de prueba de la app debe usar como base.
"""

import os

import pytest
from pytest_bdd import given, parsers, scenarios, then, when

from bateria.driver.web import PantallaWeb
from bateria.servidor import ServidorSimulado

scenarios("../features/hoy.feature")


@pytest.fixture
def escenario(pagina):
    contexto = {"pagina": pagina, "servidor": None, "pantalla": None}
    yield contexto
    if contexto["servidor"] is not None:
        contexto["servidor"].__exit__(None, None, None)


def _abrir(escenario):
    url = os.environ.get("BATERIA_APP_URL")
    if not url:
        pytest.fail(
            "falta BATERIA_APP_URL: todavía no existe una compilación web de la app "
            "para la batería"
        )
    escenario["pagina"].goto(url)
    escenario["pantalla"] = PantallaWeb(escenario["pagina"])
    escenario["pantalla"].activar_semantica()


@given("una cuenta con el entrenador básico")
def cuenta_con_entrenador_basico(escenario):
    puerto = int(os.environ.get("BATERIA_API_PUERTO", "8787"))
    servidor = ServidorSimulado(puerto=puerto)
    escenario["servidor"] = servidor.__enter__()


@when("abre la aplicación")
def abre_la_aplicacion(escenario):
    _abrir(escenario)


@when(parsers.parse("abre la aplicación con un ancho de {ancho:d} píxeles"))
def abre_la_aplicacion_con_ancho(escenario, ancho):
    escenario["pagina"].set_viewport_size({"width": ancho, "height": 844})
    _abrir(escenario)


@when("inicia una sesión de práctica")
def inicia_una_sesion(escenario):
    escenario["pantalla"].pulsar("hoy.practicar.boton")


@when("la ventana de grabación está abierta")
def la_ventana_esta_abierta(escenario):
    escenario["pantalla"].texto("sesion.estado")


@then("ve la ventana sostenida de EN→ES")
def ve_ventana_en_es(escenario):
    assert escenario["pantalla"].texto("hoy.ventana.en-es").strip()


@then("ve la ventana sostenida de ES→EN")
def ve_ventana_es_en(escenario):
    assert escenario["pantalla"].texto("hoy.ventana.es-en").strip()


@then("la navegación aparece como barra inferior")
def navegacion_barra_inferior(escenario):
    assert escenario["pantalla"].texto("hoy.navegacion.barra").strip()


@then("la navegación aparece como riel con etiquetas")
def navegacion_riel(escenario):
    assert escenario["pantalla"].texto("hoy.navegacion.riel").strip()


@then("el anillo no muestra cifras")
def anillo_sin_cifras(escenario):
    texto = escenario["pantalla"].texto("sesion.anillo")
    assert not any(caracter.isdigit() for caracter in texto), texto
