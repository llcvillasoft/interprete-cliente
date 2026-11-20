"""Cuenta las cadenas literales de la capa de presentación de la app.

Es el tope cadenas_literales_en_ui: el texto que se escribe directamente en el código
de la interfaz y no sale de un recurso externo. Un tope solo puede bajar.

No cuentan: las directivas import, export y part; las líneas que son comentario
completo; los identificadores técnicos de Semantics (identifier: '...'); y las
claves de un switch, que son valores de la máquina de estados y no texto visible.

Limitación: un comentario al final de una línea de código sí cuenta. Hoy no hay ninguno.

Uso: python -m calidad.literales app/lib/presentacion
"""

import json
import re
import sys
from pathlib import Path

_SIMPLE = r"'(?:\\.|[^'\\\n])*'"
_DOBLE = r'"(?:\\.|[^"\\\n])*"'
_LITERAL = re.compile(_SIMPLE + "|" + _DOBLE)
_IDENTIFICADOR = re.compile(r"identifier:\s*(?:" + _SIMPLE + "|" + _DOBLE + ")")
_CLAVE_DE_SWITCH = re.compile(r"(?:" + _SIMPLE + "|" + _DOBLE + r")\s*=>")
_DIRECTIVA = re.compile(r"^(import|export|part)\s")


def contar_linea(linea: str) -> int:
    texto = linea.strip()
    if _DIRECTIVA.match(texto) or texto.startswith("//"):
        return 0
    sin_identificadores = _IDENTIFICADOR.sub("", linea)
    sin_claves = _CLAVE_DE_SWITCH.sub("", sin_identificadores)
    return len(_LITERAL.findall(sin_claves))


def contar_archivo(ruta: Path) -> int:
    texto = Path(ruta).read_text(encoding="utf-8")
    return sum(contar_linea(linea) for linea in texto.splitlines())


def contar_directorio(directorio: Path) -> int:
    return sum(contar_archivo(ruta) for ruta in sorted(Path(directorio).rglob("*.dart")))


def main(argv=None) -> int:
    argumentos = sys.argv[1:] if argv is None else argv
    if len(argumentos) != 1:
        print("Uso: python -m calidad.literales carpeta-de-presentacion", file=sys.stderr)
        return 2
    directorio = Path(argumentos[0])
    if not directorio.is_dir():
        print(f"No existe la carpeta {directorio}", file=sys.stderr)
        return 2
    print(json.dumps({"cadenas_literales_en_ui": contar_directorio(directorio)}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
