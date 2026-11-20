"""Comprueba unas medidas contra la línea base desde la línea de órdenes.

Uso: python -m calidad.evaluar linea-base.json medidas.json [--parcial]

Con --parcial solo se evalúan las métricas que tienen medida, para que una
ejecución que mide una parte (por ejemplo, Lighthouse) no falle por el resto.
"""

import argparse
import json
import sys
from pathlib import Path

from calidad import ratchet


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Comprueba medidas contra la línea base.")
    parser.add_argument("base", type=Path)
    parser.add_argument("medidas", type=Path)
    parser.add_argument("--parcial", action="store_true")
    args = parser.parse_args(argv)

    try:
        base = ratchet.cargar(args.base)
    except ratchet.ReglaInvalida as error:
        print(f"Línea base no válida: {error}", file=sys.stderr)
        return 2

    medidas = json.loads(args.medidas.read_text(encoding="utf-8"))
    if args.parcial:
        base = {**base, "metricas": {n: r for n, r in base["metricas"].items() if n in medidas}}

    violaciones = ratchet.evaluar(base, medidas)
    for violacion in violaciones:
        print(violacion)
    if violaciones:
        return 1
    print(f"{len(base['metricas'])} métricas dentro de la línea base")
    return 0


if __name__ == "__main__":
    sys.exit(main())
