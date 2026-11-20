import os
import shutil

import pytest
from playwright.sync_api import sync_playwright


@pytest.fixture(scope="session")
def navegador():
    """Chromium para la batería. BATERIA_NAVEGADOR permite apuntar a un binario concreto."""
    ruta = os.environ.get("BATERIA_NAVEGADOR") or shutil.which("google-chrome")
    with sync_playwright() as playwright:
        navegador = playwright.chromium.launch(executable_path=ruta, headless=True)
        yield navegador
        navegador.close()


@pytest.fixture
def pagina(navegador):
    """Página nueva con el viewport compacto de referencia (390 × 844)."""
    contexto = navegador.new_context(viewport={"width": 390, "height": 844})
    pagina = contexto.new_page()
    yield pagina
    contexto.close()
