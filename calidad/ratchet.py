"""Ratchets de calidad y de rendimiento.

Cada medida tiene una regla en la línea base y solo puede mejorar:

- tope: conteo de defectos (menos es mejor). Falla si la medida supera valor + tolerancia.
- suelo: puntuación (más es mejor). Falla si la medida queda por debajo de valor - tolerancia.

La actualización sube la línea base cuando una medida mejora y nunca la afloja.
"""

import copy
import json
from pathlib import Path

TIPOS = {"tope", "suelo"}


class ReglaInvalida(ValueError):
    """Una regla de la línea base no está bien formada."""


def _validar_regla(nombre: str, regla: dict) -> None:
    if regla.get("tipo") not in TIPOS:
        raise ReglaInvalida(f"{nombre}: tipo desconocido {regla.get('tipo')!r}")
    if "valor" not in regla:
        raise ReglaInvalida(f"{nombre}: falta el valor de la línea base")


def cargar(ruta: Path) -> dict:
    base = json.loads(Path(ruta).read_text(encoding="utf-8"))
    for nombre, regla in base["metricas"].items():
        _validar_regla(nombre, regla)
    return base


def evaluar(base: dict, medidas: dict) -> list[str]:
    violaciones = []
    for nombre, regla in base["metricas"].items():
        _validar_regla(nombre, regla)
        if nombre not in medidas:
            violaciones.append(f"{nombre}: falta la medida")
            continue
        medida = medidas[nombre]
        valor = regla["valor"]
        tolerancia = regla.get("tolerancia", 0)
        if regla["tipo"] == "tope" and medida > valor + tolerancia:
            violaciones.append(f"{nombre}: {medida} supera el tope {valor}")
        if regla["tipo"] == "suelo" and medida < valor - tolerancia:
            violaciones.append(
                f"{nombre}: {medida} está por debajo del suelo {valor} "
                f"(tolerancia {tolerancia})"
            )
    return violaciones


def actualizar(base: dict, medidas: dict) -> dict:
    nueva = copy.deepcopy(base)
    for nombre, regla in nueva["metricas"].items():
        _validar_regla(nombre, regla)
        if nombre not in medidas:
            continue
        medida = medidas[nombre]
        if regla["tipo"] == "tope" and medida < regla["valor"]:
            regla["valor"] = medida
        elif regla["tipo"] == "suelo" and medida > regla["valor"]:
            regla["valor"] = medida
    return nueva
