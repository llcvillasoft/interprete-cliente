"""Contrato de identificadores de semántica compartido por la app y la batería.

El contrato vive en contrato/identificadores.json, en la raíz del repositorio,
para que el cliente Flutter y la batería lean la misma lista.
"""

import json
from pathlib import Path

RUTA_CONTRATO = Path(__file__).resolve().parents[2] / "contrato" / "identificadores.json"


class IdentificadorDesconocido(KeyError):
    """Un escenario usó un identificador que no está en el contrato."""


def _pantallas() -> dict[str, list[str]]:
    datos = json.loads(RUTA_CONTRATO.read_text(encoding="utf-8"))
    return datos["pantallas"]


def identificadores_de(pantalla: str) -> list[str]:
    return list(_pantallas()[pantalla])


def todos_los_identificadores() -> list[str]:
    return [ident for ids in _pantallas().values() for ident in ids]


def validar_identificador(identificador: str) -> str:
    if identificador not in todos_los_identificadores():
        raise IdentificadorDesconocido(identificador)
    return identificador
