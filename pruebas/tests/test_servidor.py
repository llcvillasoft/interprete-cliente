import json
import urllib.error
import urllib.request

import pytest

from bateria.fixtures import cargar
from bateria.servidor import ServidorSimulado


def _pedir(url, metodo="GET", cuerpo=None):
    peticion = urllib.request.Request(url, method=metodo, data=cuerpo)
    with urllib.request.urlopen(peticion) as respuesta:
        return respuesta.status, json.loads(respuesta.read())


def test_get_catalog_sirve_el_fixture_del_catalogo():
    with ServidorSimulado() as servidor:
        estado, cuerpo = _pedir(servidor.url + "/v1/catalog")
    assert estado == 200
    assert cuerpo == cargar("catalogo")


def test_get_me_sirve_el_fixture_de_la_cuenta():
    with ServidorSimulado() as servidor:
        estado, cuerpo = _pedir(servidor.url + "/v1/me")
    assert estado == 200
    assert cuerpo == cargar("me")


def test_post_sessions_crea_la_sesion_de_prueba():
    with ServidorSimulado() as servidor:
        estado, cuerpo = _pedir(servidor.url + "/v1/sessions", "POST", b"{}")
    assert estado == 201
    assert cuerpo == cargar("sesion")


def test_una_ruta_no_prevista_responde_404():
    with ServidorSimulado() as servidor:
        with pytest.raises(urllib.error.HTTPError) as error:
            _pedir(servidor.url + "/v1/no-existe")
    assert error.value.code == 404


def test_el_servidor_solo_escucha_en_el_equipo_local():
    with ServidorSimulado() as servidor:
        assert servidor.url.startswith("http://127.0.0.1:")


def test_al_salir_del_contexto_el_servidor_deja_de_responder():
    with ServidorSimulado() as servidor:
        url = servidor.url + "/v1/catalog"
    with pytest.raises(urllib.error.URLError):
        _pedir(url)


def test_el_servidor_escucha_en_el_puerto_pedido():
    import socket

    with socket.socket() as sonda:
        sonda.bind(("127.0.0.1", 0))
        puerto = sonda.getsockname()[1]
    with ServidorSimulado(puerto=puerto) as servidor:
        assert servidor.url == f"http://127.0.0.1:{puerto}"
