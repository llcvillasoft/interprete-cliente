"""Fixtures de la API simulada.

Cada respuesta del servidor de prueba sale de un archivo JSON en pruebas/fixtures.
Antes de servir un fixture se valida contra el esquema que le corresponde en
contrato/openapi.json, copia del contrato del backend. Así un dato mal escrito
falla aquí y no dentro de una pantalla.
"""

import json
from functools import lru_cache
from pathlib import Path

from jsonschema import Draft202012Validator, ValidationError

RUTA_FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"
RUTA_CONTRATO = Path(__file__).resolve().parents[2] / "contrato" / "openapi.json"

ESQUEMAS = {
    "token": "TokenResponse",
    "catalogo": "CatalogList",
    "me": "Me",
    "me_entitlements": "EntitlementList",
    "sesion": "SessionCreated",
    "progreso_levels_en_es": "ProgressSeries",
    "progreso_levels_es_en": "ProgressSeries",
}


class FixtureInvalido(ValueError):
    """Un fixture no respeta el esquema del contrato que le corresponde."""


def cargar(nombre: str, carpeta: Path = RUTA_FIXTURES) -> dict:
    ruta = Path(carpeta) / f"{nombre}.json"
    datos = json.loads(ruta.read_text(encoding="utf-8"))
    _validar(nombre, datos)
    return datos


def nombres_disponibles(carpeta: Path = RUTA_FIXTURES) -> list[str]:
    return sorted(ruta.stem for ruta in Path(carpeta).glob("*.json"))


@lru_cache(maxsize=1)
def _esquemas() -> dict:
    contrato = json.loads(RUTA_CONTRATO.read_text(encoding="utf-8"))
    esquemas = contrato["components"]["schemas"]
    # El contrato apunta a components/schemas; jsonschema busca las referencias en $defs.
    return json.loads(json.dumps(esquemas).replace("#/components/schemas/", "#/$defs/"))


def _validar(nombre: str, datos: dict) -> None:
    if nombre not in ESQUEMAS:
        raise FixtureInvalido(f"{nombre}: sin esquema en el contrato")
    raiz = {"$defs": _esquemas(), "$ref": f"#/$defs/{ESQUEMAS[nombre]}"}
    try:
        Draft202012Validator(raiz).validate(datos)
    except ValidationError as error:
        raise FixtureInvalido(f"{nombre}: {error.message}") from error
