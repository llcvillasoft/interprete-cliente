"""Integra la biblioteca nativa de audio en windows/CMakeLists.txt, generado por flutter create.

Uso desde app/: python tool/integrar_audio_core_windows.py windows/CMakeLists.txt

Añade al final del archivo el subdirectorio de native/audio_core y la instalación de
audio_core.dll en CMAKE_INSTALL_PREFIX, que es donde la plantilla instala el ejecutable.
Así la DLL queda junto a interprete_cliente.exe en el paquete. Si el archivo ya tiene la
integración, no cambia nada.
"""

import re
import sys
from pathlib import Path

MARCADOR = "# Biblioteca nativa de audio (native/audio_core), añadida por CI."

# La plantilla de flutter create instala el ejecutable en CMAKE_INSTALL_PREFIX. Si esa línea
# cambia, la DLL no iría al mismo sitio, así que el integrador se detiene en vez de instalarla mal.
_INSTALACION_DEL_EJECUTABLE = re.compile(
    r'install\(\s*TARGETS\s+\$\{BINARY_NAME\}\s+RUNTIME\s+DESTINATION\s+"\$\{CMAKE_INSTALL_PREFIX\}"'
)

BLOQUE = """
{marcador}
add_subdirectory("${{CMAKE_CURRENT_SOURCE_DIR}}/../native/audio_core" "${{CMAKE_CURRENT_BINARY_DIR}}/audio_core")
# El cargador de Dart abre audio_core.dll. Fijar el prefijo hace que el nombre sea ese con
# cualquier compilador (MSVC no añade prefijo; MinGW añadiría lib).
set_target_properties(audio_core PROPERTIES PREFIX "")
install(TARGETS audio_core RUNTIME DESTINATION "${{CMAKE_INSTALL_PREFIX}}" COMPONENT Runtime)
""".format(marcador=MARCADOR)


class PlantillaInesperada(Exception):
    """La plantilla de flutter create no tiene la instalación del ejecutable que se espera."""


def integrar(ruta: Path) -> bool:
    """Añade la integración a ruta. Devuelve False si el archivo ya la tenía."""
    ruta = Path(ruta)
    texto = ruta.read_text(encoding="utf-8")
    if MARCADOR in texto:
        return False
    if not _INSTALACION_DEL_EJECUTABLE.search(texto):
        raise PlantillaInesperada(
            f"{ruta}: no está la instalación del ejecutable en CMAKE_INSTALL_PREFIX; "
            "la DLL no se instalaría junto a él"
        )
    ruta.write_text(texto + BLOQUE, encoding="utf-8")
    return True


def main(argumentos=None) -> int:
    argumentos = sys.argv[1:] if argumentos is None else argumentos
    if len(argumentos) != 1:
        print("Uso: python tool/integrar_audio_core_windows.py windows/CMakeLists.txt", file=sys.stderr)
        return 2
    ruta = Path(argumentos[0])
    try:
        cambio = integrar(ruta)
    except FileNotFoundError:
        print(f"No existe {ruta}. ¿Se ha ejecutado flutter create --platforms=windows?", file=sys.stderr)
        return 1
    except PlantillaInesperada as error:
        print(error, file=sys.stderr)
        return 1
    print("Integración añadida." if cambio else "La integración ya estaba.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
