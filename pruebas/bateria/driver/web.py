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
        # Flutter inserta el marcador de semántica tras cargar el script, así que se espera a que llegue.
        # Si nunca llega, la semántica ya estaba activa y la comprobación de abajo decide.
        marcador = self._pagina.locator("flt-semantics-placeholder").first
        try:
            marcador.wait_for(state="attached", timeout=self._espera_ms)
            marcador.dispatch_event("click")
        except ErrorPlaywright:
            pass
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
        nodo = elemento.first
        # Un nodo contenedor de Flutter no tiene texto propio: su etiqueta va en aria-label.
        return nodo.text_content() or nodo.get_attribute("aria-label") or ""

    def pulsar(self, identificador: str) -> None:
        elemento = self.elemento(identificador)
        try:
            elemento.first.click(timeout=self._espera_ms)
        except ErrorPlaywright as error:
            raise ElementoNoEncontrado(
                f"no se pudo pulsar el identificador {identificador}"
            ) from error
