import json

import pytest

from lighthouse import InformeInvalido, medidas_desde_informe


def informe(**puntuaciones):
    categorias = {}
    for identificador, puntuacion in puntuaciones.items():
        categorias[identificador] = {"id": identificador, "score": puntuacion}
    return {"categories": categorias}


def todas(rendimiento=0.43, accesibilidad=0.91, practicas=0.96, seo=0.82):
    return informe(
        performance=rendimiento,
        accessibility=accesibilidad,
        **{"best-practices": practicas},
        seo=seo,
    )


def test_convierte_cada_categoria_en_una_medida_entera_de_cien():
    medidas = medidas_desde_informe(todas())
    assert medidas == {
        "lighthouse.rendimiento": 43,
        "lighthouse.accesibilidad": 91,
        "lighthouse.buenas_practicas": 96,
        "lighthouse.seo": 82,
    }


def test_redondea_como_lighthouse_y_no_trunca():
    medidas = medidas_desde_informe(todas(rendimiento=0.999))
    assert medidas["lighthouse.rendimiento"] == 100


def test_un_informe_sin_categorias_se_rechaza():
    with pytest.raises(InformeInvalido, match="categories"):
        medidas_desde_informe({"lighthouseVersion": "12.0.0"})


def test_una_categoria_que_falta_se_rechaza_con_su_nombre():
    incompleto = todas()
    del incompleto["categories"]["seo"]
    with pytest.raises(InformeInvalido, match="seo"):
        medidas_desde_informe(incompleto)


def test_una_categoria_sin_puntuacion_se_rechaza():
    sin_puntuacion = todas()
    sin_puntuacion["categories"]["performance"]["score"] = None
    with pytest.raises(InformeInvalido, match="performance"):
        medidas_desde_informe(sin_puntuacion)


def test_la_linea_de_ordenes_escribe_las_medidas_en_json(tmp_path, capsys):
    from lighthouse import main

    ruta = tmp_path / "lighthouse.json"
    ruta.write_text(json.dumps(todas()), encoding="utf-8")
    assert main([str(ruta)]) == 0
    assert json.loads(capsys.readouterr().out)["lighthouse.rendimiento"] == 43


def test_un_archivo_que_no_es_json_sale_con_codigo_2(tmp_path, capsys):
    from lighthouse import main

    ruta = tmp_path / "lighthouse.json"
    ruta.write_text("no es json", encoding="utf-8")
    assert main([str(ruta)]) == 2
    assert "no es JSON" in capsys.readouterr().err


def test_un_archivo_que_no_existe_sale_con_codigo_2(tmp_path, capsys):
    from lighthouse import main

    assert main([str(tmp_path / "no-existe.json")]) == 2
    assert "No se puede leer el archivo" in capsys.readouterr().err
