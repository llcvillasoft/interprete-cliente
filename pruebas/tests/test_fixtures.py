import json

import pytest

from bateria.fixtures import FixtureInvalido, cargar, nombres_disponibles


def _escribir(carpeta, nombre, datos):
    (carpeta / f"{nombre}.json").write_text(json.dumps(datos), encoding="utf-8")


def test_el_catalogo_de_fixtures_incluye_el_modulo_base_gratuito():
    catalogo = cargar("catalogo")
    base = next(m for m in catalogo["modulos"] if m["id"] == "base")
    assert base["access"]["state"] == "free"


def test_un_fixture_sin_una_clave_requerida_se_rechaza(tmp_path):
    _escribir(tmp_path, "hoy", {"otra_cosa": []})
    with pytest.raises(FixtureInvalido, match="ventanas"):
        cargar("hoy", carpeta=tmp_path)


def test_un_estado_de_acceso_fuera_de_los_previstos_se_rechaza(tmp_path):
    datos = {
        "modulos": [
            {"id": "base", "access": {"state": "gratis-para-siempre", "expires_at": None}}
        ]
    }
    _escribir(tmp_path, "catalogo", datos)
    with pytest.raises(FixtureInvalido, match="gratis-para-siempre"):
        cargar("catalogo", carpeta=tmp_path)


def test_todos_los_fixtures_del_repositorio_son_validos():
    nombres = nombres_disponibles()
    assert {"catalogo", "me", "hoy", "sesion"} <= set(nombres)
    for nombre in nombres:
        assert isinstance(cargar(nombre), dict)
