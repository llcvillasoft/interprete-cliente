"""API simulada para la batería de interfaz.

Sirve los fixtures por HTTP en 127.0.0.1 y en un puerto efímero. No es el backend:
no calcula nada, solo responde con datos de prueba en la forma de contrato/openapi.json.
Solo existen las rutas que usa la app; cualquier otra responde 404 con ErrorBody.
"""

import json
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

from bateria.fixtures import RUTA_FIXTURES, cargar

# (método, ruta) -> (estado, fixture, exige token)
RUTAS = {
    ("POST", "/v1/auth/token"): (200, "token", False),
    ("GET", "/v1/catalog"): (200, "catalogo", True),
    ("GET", "/v1/me"): (200, "me", True),
    ("GET", "/v1/me/entitlements"): (200, "me_entitlements", True),
    ("POST", "/v1/sessions"): (201, "sesion", True),
    ("GET", "/v1/progress"): (200, None, True),
}

# La serie de progreso depende de la métrica y de la dirección de la consulta.
PROGRESO = {
    ("levels", "en_es"): "progreso_levels_en_es",
    ("levels", "es_en"): "progreso_levels_es_en",
}

CABECERAS_CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
}


def _manejador(carpeta: Path):
    token_valido = cargar("token", carpeta)["token"]

    class Manejador(BaseHTTPRequestHandler):
        def do_GET(self):
            self._responder("GET")

        def do_POST(self):
            longitud = int(self.headers.get("Content-Length", 0))
            self.rfile.read(longitud)
            self._responder("POST")

        def do_OPTIONS(self):
            self.send_response(204)
            for nombre, valor in CABECERAS_CORS.items():
                self.send_header(nombre, valor)
            self.send_header("Content-Length", "0")
            self.end_headers()

        def _responder(self, metodo: str) -> None:
            partes = urlsplit(self.path)
            ruta = partes.path
            destino = RUTAS.get((metodo, ruta))
            if destino is None:
                self._enviar(404, {"error": "not_found"})
                return
            estado, nombre, exige_token = destino
            if exige_token and self.headers.get("Authorization") != f"Bearer {token_valido}":
                self._enviar(401, {"error": "unauthorized"})
                return
            if ruta == "/v1/progress":
                consulta = parse_qs(partes.query)
                clave = (consulta.get("metric", [""])[0], consulta.get("direction", [""])[0])
                nombre = PROGRESO.get(clave)
                if nombre is None:
                    self._enviar(404, {"error": "not_found"})
                    return
            self._enviar(estado, cargar(nombre, carpeta))

        def _enviar(self, estado: int, cuerpo: dict) -> None:
            datos = json.dumps(cuerpo).encode("utf-8")
            self.send_response(estado)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(datos)))
            for nombre, valor in CABECERAS_CORS.items():
                self.send_header(nombre, valor)
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
