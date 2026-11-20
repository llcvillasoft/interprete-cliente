import json
import urllib.error
import urllib.request

import pytest

from bateria.fixtures import cargar
from bateria.servidor import ServidorSimulado

TOKEN = cargar("token")["token"]


def _pedir(url, metodo="GET", cuerpo=None, token=TOKEN):
    cabeceras = {}
    if token is not None:
        cabeceras["Authorization"] = f"Bearer {token}"
    if cuerpo is not None:
        cabeceras["Content-Type"] = "application/json"
    peticion = urllib.request.Request(url, method=metodo, data=cuerpo, headers=cabeceras)
    with urllib.request.urlopen(peticion) as respuesta:
        return respuesta.status, json.loads(respuesta.read())


def test_post_auth_token_devuelve_el_token_de_prueba():
    cuerpo = json.dumps({"device_id": "dispositivo-prueba-001", "secret": "secreto-de-prueba"})
    with ServidorSimulado() as servidor:
        estado, datos = _pedir(
            servidor.url + "/v1/auth/token", "POST", cuerpo.encode("utf-8"), token=None
        )
    assert estado == 200
    assert datos == cargar("token")


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


def test_get_me_entitlements_sirve_los_permisos_de_la_cuenta():
    with ServidorSimulado() as servidor:
        estado, cuerpo = _pedir(servidor.url + "/v1/me/entitlements")
    assert estado == 200
    assert cuerpo == cargar("me_entitlements")


def test_post_sessions_crea_la_sesion_de_prueba():
    with ServidorSimulado() as servidor:
        estado, cuerpo = _pedir(servidor.url + "/v1/sessions", "POST", b"{}")
    assert estado == 201
    assert cuerpo == cargar("sesion")


def test_get_progress_levels_sirve_la_serie_de_en_es():
    with ServidorSimulado() as servidor:
        estado, cuerpo = _pedir(
            servidor.url + "/v1/progress?metric=levels&direction=en_es"
        )
    assert estado == 200
    assert cuerpo == cargar("progreso_levels_en_es")


def test_get_progress_levels_sirve_la_serie_de_es_en_por_separado():
    with ServidorSimulado() as servidor:
        estado, cuerpo = _pedir(
            servidor.url + "/v1/progress?metric=levels&direction=es_en"
        )
    assert estado == 200
    assert cuerpo == cargar("progreso_levels_es_en")


def test_una_ruta_protegida_sin_token_responde_401():
    with ServidorSimulado() as servidor:
        with pytest.raises(urllib.error.HTTPError) as error:
            _pedir(servidor.url + "/v1/me", token=None)
    assert error.value.code == 401


def test_las_respuestas_permiten_el_origen_de_la_app():
    with ServidorSimulado() as servidor:
        peticion = urllib.request.Request(
            servidor.url + "/v1/catalog", headers={"Authorization": f"Bearer {TOKEN}"}
        )
        with urllib.request.urlopen(peticion) as respuesta:
            cabecera = respuesta.headers.get("Access-Control-Allow-Origin")
    assert cabecera == "*"


def test_la_comprobacion_previa_del_navegador_responde_204_sin_token():
    with ServidorSimulado() as servidor:
        peticion = urllib.request.Request(servidor.url + "/v1/sessions", method="OPTIONS")
        with urllib.request.urlopen(peticion) as respuesta:
            estado = respuesta.status
            metodos = respuesta.headers.get("Access-Control-Allow-Methods", "")
            cabeceras = respuesta.headers.get("Access-Control-Allow-Headers", "")
    assert estado == 204
    assert "POST" in metodos
    assert "Content-Type" in cabeceras
    assert "Authorization" in cabeceras


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
