import json

import pytest

from ratchet import ReglaInvalida, actualizar, cargar, evaluar

BASE = {
    "version": 1,
    "metricas": {
        "cadenas_literales_en_ui": {"tipo": "tope", "valor": 3},
        "lighthouse.rendimiento": {"tipo": "suelo", "valor": 70, "tolerancia": 2},
    },
}


def test_un_tope_que_se_cumple_no_produce_violaciones():
    medidas = {"cadenas_literales_en_ui": 2, "lighthouse.rendimiento": 80}
    assert evaluar(BASE, medidas) == []


def test_un_tope_superado_produce_una_violacion_con_el_nombre_de_la_medida():
    medidas = {"cadenas_literales_en_ui": 4, "lighthouse.rendimiento": 80}
    violaciones = evaluar(BASE, medidas)
    assert len(violaciones) == 1
    assert "cadenas_literales_en_ui" in violaciones[0]


def test_un_suelo_dentro_de_la_tolerancia_pasa():
    medidas = {"cadenas_literales_en_ui": 3, "lighthouse.rendimiento": 68}
    assert evaluar(BASE, medidas) == []


def test_un_suelo_por_debajo_de_la_tolerancia_falla():
    medidas = {"cadenas_literales_en_ui": 3, "lighthouse.rendimiento": 67}
    violaciones = evaluar(BASE, medidas)
    assert len(violaciones) == 1
    assert "lighthouse.rendimiento" in violaciones[0]


def test_una_medida_faltante_falla_en_lugar_de_pasar_en_silencio():
    violaciones = evaluar(BASE, {"cadenas_literales_en_ui": 0})
    assert any("lighthouse.rendimiento" in v and "falta" in v for v in violaciones)


def test_un_tipo_de_regla_desconocido_se_rechaza():
    base = {"version": 1, "metricas": {"x": {"tipo": "aproximado", "valor": 1}}}
    with pytest.raises(ReglaInvalida):
        evaluar(base, {"x": 1})


def test_actualizar_baja_un_tope_cuando_la_medida_mejora():
    nueva = actualizar(BASE, {"cadenas_literales_en_ui": 1, "lighthouse.rendimiento": 80})
    assert nueva["metricas"]["cadenas_literales_en_ui"]["valor"] == 1


def test_actualizar_no_sube_un_tope_cuando_la_medida_empeora():
    nueva = actualizar(BASE, {"cadenas_literales_en_ui": 9, "lighthouse.rendimiento": 80})
    assert nueva["metricas"]["cadenas_literales_en_ui"]["valor"] == 3


def test_actualizar_sube_un_suelo_cuando_la_medida_mejora():
    nueva = actualizar(BASE, {"cadenas_literales_en_ui": 3, "lighthouse.rendimiento": 85})
    assert nueva["metricas"]["lighthouse.rendimiento"]["valor"] == 85


def test_actualizar_no_baja_un_suelo_cuando_la_medida_empeora():
    nueva = actualizar(BASE, {"cadenas_literales_en_ui": 3, "lighthouse.rendimiento": 60})
    assert nueva["metricas"]["lighthouse.rendimiento"]["valor"] == 70


def test_actualizar_no_modifica_la_linea_base_original():
    copia = json.loads(json.dumps(BASE))
    actualizar(BASE, {"cadenas_literales_en_ui": 0, "lighthouse.rendimiento": 99})
    assert BASE == copia


def test_la_linea_base_del_repositorio_es_valida():
    from pathlib import Path

    base = cargar(Path(__file__).resolve().parents[1] / "linea-base.json")
    assert base["metricas"], "la línea base no tiene métricas"
