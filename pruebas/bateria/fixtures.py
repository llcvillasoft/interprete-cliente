"""Fixtures de la API simulada.

Cada respuesta del servidor de prueba sale de un archivo JSON en pruebas/fixtures.
Antes de servir un fixture se comprueba su forma, para que un dato mal escrito
falle aquí y no dentro de una pantalla.
"""

import json
from pathlib import Path

RUTA_FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"

ESTADOS_ACCESO = {"free", "active", "locked", "expired"}

REQUISITOS = {
    "catalogo": ["modulos"],
    "me": ["id", "language_pairs", "entitlements"],
    "hoy": ["ventanas"],
    "sesion": ["id", "product", "max_turns", "state"],
}


class FixtureInvalido(ValueError):
    """Un fixture no respeta la forma que la app espera."""


def cargar(nombre: str, carpeta: Path = RUTA_FIXTURES) -> dict:
    ruta = Path(carpeta) / f"{nombre}.json"
    datos = json.loads(ruta.read_text(encoding="utf-8"))
    _validar(nombre, datos)
    return datos


def nombres_disponibles(carpeta: Path = RUTA_FIXTURES) -> list[str]:
    return sorted(ruta.stem for ruta in Path(carpeta).glob("*.json"))


def _validar(nombre: str, datos: dict) -> None:
    for clave in REQUISITOS.get(nombre, []):
        if clave not in datos:
            raise FixtureInvalido(f"{nombre}: falta la clave «{clave}»")
    if nombre == "catalogo":
        for modulo in datos["modulos"]:
            estado = modulo.get("access", {}).get("state")
            if estado not in ESTADOS_ACCESO:
                raise FixtureInvalido(
                    f"catalogo: estado de acceso no previsto: {estado}"
                )
