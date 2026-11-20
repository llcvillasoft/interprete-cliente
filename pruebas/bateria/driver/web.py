"""Driver web: localiza elementos de Flutter web por su identificador de semántica.

Flutter pinta la interfaz sobre un canvas. La única capa del DOM que se puede
localizar es la semántica, y solo existe tras activarla. Cada nodo lleva el
atributo flt-semantics-identifier con el valor del contrato.
"""

from playwright.sync_api import Error as ErrorPlaywright
from playwright.sync_api import Page

from bateria.contrato import validar_identificador


class ElementoNoEncontrado(Exception):
    """El identificador no apareció dentro del tiempo de espera."""


class PantallaWeb:
    def __init__(self, pagina: Page, espera_ms: int = 5000):
        self._pagina = pagina
        self._espera_ms = espera_ms

    def activar_semantica(self) -> None:
        marcador = self._pagina.locator("flt-semantics-placeholder")
        if marcador.count():
            marcador.dispatch_event("click")
        try:
            self._pagina.locator("[flt-semantics-identifier]").first.wait_for(
                state="attached", timeout=self._espera_ms
            )
        except ErrorPlaywright as error:
            raise ElementoNoEncontrado(
                "la semántica de Flutter no apareció tras activarla"
            ) from error

    def elemento(self, identificador: str):
        validar_identificador(identificador)
        return self._pagina.locator(f'[flt-semantics-identifier="{identificador}"]')

    def texto(self, identificador: str) -> str:
        elemento = self.elemento(identificador)
        try:
            elemento.first.wait_for(state="attached", timeout=self._espera_ms)
        except ErrorPlaywright as error:
            raise ElementoNoEncontrado(
                f"no apareció el identificador {identificador} "
                f"tras {self._espera_ms} ms"
            ) from error
        return elemento.first.text_content() or ""

    def pulsar(self, identificador: str) -> None:
        elemento = self.elemento(identificador)
        try:
            elemento.first.click(timeout=self._espera_ms)
        except ErrorPlaywright as error:
            raise ElementoNoEncontrado(
                f"no se pudo pulsar el identificador {identificador}"
            ) from error
