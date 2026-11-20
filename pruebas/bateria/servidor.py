"""API simulada para la batería de interfaz.

Sirve los fixtures por HTTP en 127.0.0.1 y en un puerto efímero. No es el backend:
no calcula nada, solo responde con datos de prueba en la forma que la app espera.
Las rutas se limitan a las que la guía del cliente documenta.
"""

import json
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from bateria.fixtures import RUTA_FIXTURES, cargar

RUTAS = {
    ("GET", "/v1/catalog"): (200, "catalogo"),
    ("GET", "/v1/me"): (200, "me"),
    ("POST", "/v1/sessions"): (201, "sesion"),
}


def _manejador(carpeta: Path):
    class Manejador(BaseHTTPRequestHandler):
        def do_GET(self):
            self._responder("GET")

        def do_POST(self):
            longitud = int(self.headers.get("Content-Length", 0))
            self.rfile.read(longitud)
            self._responder("POST")

        def _responder(self, metodo: str) -> None:
            ruta = self.path.split("?", 1)[0]
            destino = RUTAS.get((metodo, ruta))
            if destino is None:
                self._enviar(404, {"error": "not_found", "path": ruta})
                return
            estado, nombre = destino
            self._enviar(estado, cargar(nombre, carpeta))

        def _enviar(self, estado: int, cuerpo: dict) -> None:
            datos = json.dumps(cuerpo).encode("utf-8")
            self.send_response(estado)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(datos)))
            self.end_headers()
            self.wfile.write(datos)

        def log_message(self, formato, *argumentos):
            return

    return Manejador


class ServidorSimulado:
    """Contexto que levanta la API simulada y la detiene al salir."""

    def __init__(self, carpeta: Path = RUTA_FIXTURES, puerto: int = 0):
        self._carpeta = carpeta
        self._puerto = puerto
        self._httpd = None
        self._hilo = None

    @property
    def url(self) -> str:
        return f"http://127.0.0.1:{self._httpd.server_address[1]}"

    def __enter__(self) -> "ServidorSimulado":
        self._httpd = ThreadingHTTPServer(("127.0.0.1", self._puerto), _manejador(self._carpeta))
        self._httpd.daemon_threads = True
        self._hilo = threading.Thread(target=self._httpd.serve_forever, daemon=True)
        self._hilo.start()
        return self

    def __exit__(self, *excepcion) -> None:
        self._httpd.shutdown()
        self._httpd.server_close()
        self._hilo.join(timeout=5)
