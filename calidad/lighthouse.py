"""Convierte un informe JSON de Lighthouse en medidas para los ratchets.

Lighthouse da cada categoría como una puntuación entre 0 y 1. Aquí se pasa a una
escala de 0 a 100, redondeada igual que Lighthouse la muestra (como Math.round de JavaScript).
"""

import json
import math
import sys
from pathlib import Path

CATEGORIAS = {
    "performance": "lighthouse.rendimiento",
    "accessibility": "lighthouse.accesibilidad",
    "best-practices": "lighthouse.buenas_practicas",
    "seo": "lighthouse.seo",
}


class InformeInvalido(ValueError):
    """El informe no trae una de las categorías que se miden."""


def medidas_desde_informe(informe: dict) -> dict:
    categorias = informe.get("categories")
    if not isinstance(categorias, dict):
        raise InformeInvalido("el informe no tiene el bloque categories")
    medidas = {}
    for identificador, nombre in CATEGORIAS.items():
        categoria = categorias.get(identificador)
        if categoria is None:
            raise InformeInvalido(f"falta la categoría {identificador}")
        puntuacion = categoria.get("score")
        if puntuacion is None:
            raise InformeInvalido(f"la categoría {identificador} no tiene puntuación")
        medidas[nombre] = math.floor(puntuacion * 100 + 0.5)
    return medidas


def main(argv=None) -> int:
    argumentos = sys.argv[1:] if argv is None else argv
    if len(argumentos) != 1:
        print("Uso: python -m calidad.lighthouse informe.json", file=sys.stderr)
        return 2
    try:
        texto = Path(argumentos[0]).read_text(encoding="utf-8")
    except OSError:
        print(f"No se puede leer el archivo {argumentos[0]}", file=sys.stderr)
        return 2
    try:
        informe = json.loads(texto)
    except json.JSONDecodeError:
        print(f"El archivo {argumentos[0]} no es JSON", file=sys.stderr)
        return 2
    try:
        medidas = medidas_desde_informe(informe)
    except InformeInvalido as error:
        print(f"Informe no válido: {error}", file=sys.stderr)
        return 2
    print(json.dumps(medidas, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
