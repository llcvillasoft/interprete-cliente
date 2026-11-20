import re

import pytest

from bateria.contrato import (
    IdentificadorDesconocido,
    identificadores_de,
    todos_los_identificadores,
    validar_identificador,
)

CONVENCION = re.compile(r"[a-z0-9]+(\.[a-z0-9-]+){1,2}")


def test_cada_pantalla_tiene_identificadores_unicos():
    for pantalla in ("hoy", "sesion"):
        ids = identificadores_de(pantalla)
        assert ids, f"la pantalla {pantalla} no tiene identificadores"
        assert len(ids) == len(set(ids)), f"hay duplicados en {pantalla}"


def test_no_hay_identificadores_repetidos_entre_pantallas():
    ids = todos_los_identificadores()
    assert len(ids) == len(set(ids))


def test_cada_identificador_sigue_la_convencion_de_nombres():
    for ident in todos_los_identificadores():
        assert CONVENCION.fullmatch(ident), f"{ident} no sigue la convención"


def test_el_contrato_incluye_lo_que_piden_los_escenarios_del_poc():
    hoy = set(identificadores_de("hoy"))
    sesion = set(identificadores_de("sesion"))
    assert {
        "hoy.ventana.en-es",
        "hoy.ventana.es-en",
        "hoy.navegacion.barra",
        "hoy.navegacion.riel",
    } <= hoy
    assert {"sesion.anillo", "sesion.estado"} <= sesion


def test_un_identificador_fuera_del_contrato_se_rechaza():
    with pytest.raises(IdentificadorDesconocido):
        validar_identificador("hoy.boton.inventado")


def test_un_identificador_del_contrato_se_acepta():
    assert validar_identificador("hoy.ventana.en-es") == "hoy.ventana.en-es"
