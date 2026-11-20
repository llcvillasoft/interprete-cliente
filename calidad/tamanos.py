"""Mide el tamaño de los JavaScript de arranque de una compilación web de Flutter.

Es el indicador de rendimiento del ratchet: pesa lo que el navegador descarga antes
de pintar la app. Se expresa en kilobytes, redondeados hacia arriba, y un tope lo
mantiene quieto o más pequeño.

Uso: python -m calidad.tamanos app/build/web
"""

import json
import math
import sys
from pathlib import Path

ARCHIVOS_DE_ARRANQUE = ("main.dart.js", "flutter.js", "flutter_bootstrap.js")


class ArchivoFaltante(ValueError):
    """La compilación no trae uno de los archivos de arranque."""


def medidas_desde_directorio(directorio: Path) -> dict:
    total = 0
    for nombre in ARCHIVOS_DE_ARRANQUE:
        ruta = Path(directorio) / nombre
        if not ruta.is_file():
            raise ArchivoFaltante(f"falta {nombre} en {directorio}")
        total += ruta.stat().st_size
    return {"rendimiento.js_kb": math.ceil(total / 1024)}


def main(argv=None) -> int:
    argumentos = sys.argv[1:] if argv is None else argv
    if len(argumentos) != 1:
        print("Uso: python -m calidad.tamanos carpeta-de-la-compilacion", file=sys.stderr)
        return 2
    try:
        medidas = medidas_desde_directorio(Path(argumentos[0]))
    except ArchivoFaltante as error:
        print(str(error), file=sys.stderr)
        return 2
    print(json.dumps(medidas, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
