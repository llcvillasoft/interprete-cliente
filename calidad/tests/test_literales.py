import json

from literales import contar_archivo, contar_directorio, main


def archivo(tmp_path, nombre, lineas):
    ruta = tmp_path / nombre
    ruta.write_text("\n".join(lineas) + "\n", encoding="utf-8")
    return ruta


def test_un_texto_visible_en_un_widget_cuenta_una_cadena(tmp_path):
    ruta = archivo(tmp_path, "a.dart", ["  child: const Text('Hoy'),"])
    assert contar_archivo(ruta) == 1


def test_las_directivas_de_importacion_no_cuentan(tmp_path):
    ruta = archivo(tmp_path, "a.dart", ["import 'package:flutter/material.dart';"])
    assert contar_archivo(ruta) == 0


def test_los_identificadores_tecnicos_no_cuentan(tmp_path):
    ruta = archivo(tmp_path, "a.dart", ["      identifier: 'hoy.practicar.boton',"])
    assert contar_archivo(ruta) == 0


def test_la_etiqueta_de_accesibilidad_si_cuenta(tmp_path):
    ruta = archivo(tmp_path, "a.dart", ["      label: 'Navegación inferior',"])
    assert contar_archivo(ruta) == 1


def test_los_comentarios_no_cuentan(tmp_path):
    ruta = archivo(tmp_path, "a.dart", ["  // Text('comentario')"])
    assert contar_archivo(ruta) == 0


def test_la_clave_de_un_switch_no_cuenta_pero_su_valor_si(tmp_path):
    ruta = archivo(tmp_path, "a.dart", ["        'created' => 'Lista para grabar',"])
    assert contar_archivo(ruta) == 1


def test_una_cadena_con_interpolacion_cuenta_como_una(tmp_path):
    ruta = archivo(tmp_path, "a.dart", ["    SnackBar(content: Text('Falló (${error.estado})'))"])
    assert contar_archivo(ruta) == 1


def test_las_comillas_dobles_tambien_cuentan(tmp_path):
    ruta = archivo(tmp_path, "a.dart", ['  final texto = "doble";'])
    assert contar_archivo(ruta) == 1


def test_una_comilla_escapada_no_corta_la_cadena(tmp_path):
    ruta = archivo(tmp_path, "a.dart", [r"  Text('It\'s here')"])
    assert contar_archivo(ruta) == 1


def test_el_directorio_suma_solo_los_archivos_dart(tmp_path):
    archivo(tmp_path, "uno.dart", ["Text('a'), Text('b')"])
    (tmp_path / "sub").mkdir()
    archivo(tmp_path / "sub", "dos.dart", ["Text('c')"])
    archivo(tmp_path, "notas.md", ["Text('no cuenta')"])
    assert contar_directorio(tmp_path) == 3


def test_la_linea_de_ordenes_escribe_la_medida_en_json(tmp_path, capsys):
    archivo(tmp_path, "a.dart", ["Text('a')"])
    assert main([str(tmp_path)]) == 0
    assert json.loads(capsys.readouterr().out) == {"cadenas_literales_en_ui": 1}


def test_una_carpeta_que_no_existe_sale_con_codigo_2(tmp_path, capsys):
    assert main([str(tmp_path / "no-existe")]) == 2
    assert "No existe la carpeta" in capsys.readouterr().err
