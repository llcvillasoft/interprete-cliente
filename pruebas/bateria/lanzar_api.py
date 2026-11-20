"""Levanta la API simulada en 127.0.0.1 y la mantiene en marcha hasta que el proceso termina.

La batería web la levanta dentro de cada escenario. Las pruebas de integración nativas
(app/integration_test) necesitan que ya esté escuchando antes de empezar, así que la CI
la arranca con este módulo. En el emulador de Android se alcanza como 10.0.2.2.
"""

import argparse
import time

from bateria.servidor import ServidorSimulado


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--puerto", type=int, default=8787)
    argumentos = parser.parse_args()
    with ServidorSimulado(puerto=argumentos.puerto):
        print(f"API simulada en 127.0.0.1:{argumentos.puerto}", flush=True)
        while True:
            time.sleep(3600)


if __name__ == "__main__":
    main()
