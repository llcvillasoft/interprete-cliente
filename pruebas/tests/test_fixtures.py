import json

import pytest

from bateria.fixtures import FixtureInvalido, cargar, nombres_disponibles


def _escribir(carpeta, nombre, datos):
    (carpeta / f"{nombre}.json").write_text(json.dumps(datos), encoding="utf-8")


def test_el_catalogo_incluye_el_modulo_base_gratuito():
    catalogo = cargar("catalogo")
    base = next(producto for producto in catalogo["products"] if producto["id"] == "base")
    assert base["access"]["state"] == "free"


def test_un_fixture_que_no_cumple_el_contrato_se_rechaza(tmp_path):
    _escribir(tmp_path, "catalogo", {"productos": []})
    with pytest.raises(FixtureInvalido, match="productos"):
        cargar("catalogo", carpeta=tmp_path)


def test_un_estado_de_acceso_fuera_del_contrato_se_rechaza(tmp_path):
    datos = cargar("catalogo")
    datos["products"][0]["access"]["state"] = "gratis-para-siempre"
    _escribir(tmp_path, "catalogo", datos)
    with pytest.raises(FixtureInvalido, match="gratis-para-siempre"):
        cargar("catalogo", carpeta=tmp_path)


def test_un_fixture_sin_esquema_en_el_contrato_se_rechaza(tmp_path):
    _escribir(tmp_path, "inventado", {})
    with pytest.raises(FixtureInvalido, match="sin esquema"):
        cargar("inventado", carpeta=tmp_path)


def test_los_fixtures_cubren_las_rutas_que_usa_la_app():
    nombres = set(nombres_disponibles())
    esperados = {
        "token",
        "catalogo",
        "me",
        "me_entitlements",
        "sesion",
        "progreso_levels_en_es",
        "progreso_levels_es_en",
    }
    assert esperados <= nombres


def test_el_fixture_de_hoy_ya_no_existe_porque_hoy_no_tiene_ruta_propia():
    assert "hoy" not in nombres_disponibles()


def test_todos_los_fixtures_del_repositorio_cumplen_el_contrato():
    for nombre in nombres_disponibles():
        assert isinstance(cargar(nombre), dict)
