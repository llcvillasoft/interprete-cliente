"""Pruebas de integrar_audio_core_windows.py sobre un windows/CMakeLists.txt de muestra.

Se ejecutan desde app/ con: python -m unittest discover -s tool -p "test_*.py"
"""

import tempfile
import unittest
from pathlib import Path

import integrar_audio_core_windows as integrador

# Fragmento de la plantilla de flutter create para Windows: la instalación del ejecutable
# va a CMAKE_INSTALL_PREFIX, y la DLL tiene que ir al mismo sitio.
PLANTILLA = """cmake_minimum_required(VERSION 3.14)
project(interprete_cliente LANGUAGES CXX)

set(BINARY_NAME "interprete_cliente")

set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)
"""


class IntegrarAudioCoreWindows(unittest.TestCase):
    def setUp(self):
        temporal = tempfile.TemporaryDirectory()
        self.addCleanup(temporal.cleanup)
        self.ruta = Path(temporal.name) / "CMakeLists.txt"

    def escribir(self, texto):
        self.ruta.write_text(texto, encoding="utf-8")

    def leer(self):
        return self.ruta.read_text(encoding="utf-8")

    def test_anade_la_biblioteca_y_su_instalacion_junto_al_ejecutable(self):
        self.escribir(PLANTILLA)

        integrador.integrar(self.ruta)

        texto = self.leer()
        self.assertIn('add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../native/audio_core"', texto)
        self.assertIn('set_target_properties(audio_core PROPERTIES PREFIX "")', texto)
        self.assertIn(
            'install(TARGETS audio_core RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"', texto
        )

    def test_conserva_el_contenido_de_la_plantilla(self):
        self.escribir(PLANTILLA)

        integrador.integrar(self.ruta)

        self.assertTrue(self.leer().startswith(PLANTILLA))

    def test_es_idempotente(self):
        self.escribir(PLANTILLA)
        self.assertTrue(integrador.integrar(self.ruta))
        una_vez = self.leer()

        self.assertFalse(integrador.integrar(self.ruta))
        self.assertEqual(una_vez, self.leer())

    def test_no_toca_el_archivo_si_la_plantilla_no_instala_el_ejecutable(self):
        sin_instalacion = PLANTILLA.replace("install(TARGETS ${BINARY_NAME}", "install(TARGETS otra_cosa")
        self.escribir(sin_instalacion)

        with self.assertRaises(integrador.PlantillaInesperada):
            integrador.integrar(self.ruta)
        self.assertEqual(sin_instalacion, self.leer())


if __name__ == "__main__":
    unittest.main()
