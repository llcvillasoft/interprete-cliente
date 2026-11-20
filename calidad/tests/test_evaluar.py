import json

from evaluar import main

BASE = {
    "version": 1,
    "metricas": {
        "cadenas_literales_en_ui": {"tipo": "tope", "valor": 0},
        "lighthouse.rendimiento": {"tipo": "suelo", "valor": 70, "tolerancia": 2},
    },
}


def escribir(tmp_path, nombre, contenido):
    ruta = tmp_path / nombre
    ruta.write_text(json.dumps(contenido), encoding="utf-8")
    return str(ruta)


def test_con_parcial_solo_se_evalua_lo_que_tiene_medida(tmp_path, capsys):
    base = escribir(tmp_path, "base.json", BASE)
    medidas = escribir(tmp_path, "medidas.json", {"lighthouse.rendimiento": 80})
    assert main([base, medidas, "--parcial"]) == 0
    assert "falta la medida" not in capsys.readouterr().out


def test_sin_parcial_una_medida_que_falta_falla(tmp_path, capsys):
    base = escribir(tmp_path, "base.json", BASE)
    medidas = escribir(tmp_path, "medidas.json", {"lighthouse.rendimiento": 80})
    assert main([base, medidas]) == 1
    assert "cadenas_literales_en_ui: falta la medida" in capsys.readouterr().out


def test_un_suelo_por_debajo_de_su_tolerancia_falla_y_lo_dice(tmp_path, capsys):
    base = escribir(tmp_path, "base.json", BASE)
    medidas = escribir(tmp_path, "medidas.json", {"lighthouse.rendimiento": 60})
    assert main([base, medidas, "--parcial"]) == 1
    salida = capsys.readouterr().out
    assert "lighthouse.rendimiento" in salida
    assert "por debajo del suelo" in salida


def test_una_base_mal_formada_sale_con_codigo_2(tmp_path, capsys):
    base = escribir(
        tmp_path,
        "base.json",
        {"metricas": {"x": {"tipo": "desconocido", "valor": 1}}},
    )
    medidas = escribir(tmp_path, "medidas.json", {"x": 1})
    assert main([base, medidas]) == 2
    assert "Línea base no válida" in capsys.readouterr().err
