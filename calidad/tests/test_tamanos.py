import json

import pytest

from tamanos import ArchivoFaltante, main, medidas_desde_directorio


def compilacion(tmp_path, **tamanos):
    for nombre, bytes_ in tamanos.items():
        (tmp_path / nombre).write_bytes(b"x" * bytes_)
    return tmp_path


def test_suma_los_javascript_de_arranque_en_kilobytes_redondeando_hacia_arriba(tmp_path):
    directorio = compilacion(
        tmp_path,
        **{"main.dart.js": 1500, "flutter.js": 1000, "flutter_bootstrap.js": 1},
    )
    assert medidas_desde_directorio(directorio) == {"rendimiento.js_kb": 3}


def test_un_archivo_que_falta_se_rechaza_con_su_nombre(tmp_path):
    directorio = compilacion(tmp_path, **{"main.dart.js": 10, "flutter.js": 10})
    with pytest.raises(ArchivoFaltante, match="flutter_bootstrap.js"):
        medidas_desde_directorio(directorio)


def test_la_linea_de_ordenes_escribe_la_medida_en_json(tmp_path, capsys):
    directorio = compilacion(
        tmp_path,
        **{"main.dart.js": 2048, "flutter.js": 0, "flutter_bootstrap.js": 0},
    )
    assert main([str(directorio)]) == 0
    assert json.loads(capsys.readouterr().out) == {"rendimiento.js_kb": 2}


def test_una_carpeta_sin_compilar_sale_con_codigo_2(tmp_path, capsys):
    assert main([str(tmp_path / "no-existe")]) == 2
    assert "falta" in capsys.readouterr().err
