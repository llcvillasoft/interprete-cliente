# Batería de interfaz (E2E con API simulada)

Batería de caja negra para la interfaz del entrenador. Recorre la aplicación desde la pantalla, con una API simulada y fixtures. No hay pruebas de integración con el backend por ahora.

## Piezas

- `../contrato/identificadores.json`: identificadores de semántica que comparten la app y la batería. Convención `pantalla.componente.variante`.
- `fixtures/`: respuestas de la API simulada. Cada fixture se valida al cargarse.
- `bateria/servidor.py`: API simulada en 127.0.0.1. Sirve solo las rutas que la guía del cliente documenta.
- `bateria/driver/web.py`: localiza elementos de Flutter web por `flt-semantics-identifier`.
- `features/hoy.feature`: escenarios de la pantalla Hoy, en español, con etiquetas `@web`, `@android`, `@ios` y `@windows`. La batería web los ejecuta con Playwright; las apps nativas, con sus pruebas de `app/integration_test/hoy_test.dart`, que siguen estos mismos escenarios.
- `bateria/lanzar_api.py`: levanta la API simulada como proceso aparte, para las pruebas nativas de la CI.
- `tests/`: pruebas de la propia batería y pasos de los escenarios.

## Ejecutar

Desde esta carpeta, con un entorno virtual:

    python3 -m venv .venv
    .venv/bin/pip install pytest pytest-bdd playwright
    .venv/bin/python -m pytest

Para el navegador, la batería usa el Chrome del sistema si lo encuentra. Otra ruta se indica con `BATERIA_NAVEGADOR`.

Los escenarios de Hoy necesitan una compilación web de la app, indicada con `BATERIA_APP_URL`. La API simulada escucha en `BATERIA_API_PUERTO` (8787 por defecto), que la compilación de prueba debe usar como base. Sin `BATERIA_APP_URL` esos escenarios fallan con un mensaje que lo dice.

## Estado

- Probado: contrato, fixtures, API simulada y driver web, contra un documento de prueba que imita la semántica de Flutter (`tests/dobles/`). Ese documento verifica el código de la batería, no la app.
- Nativo: las pruebas de integración corren en la CI en Windows (escritorio), en un simulador de iPhone y en un emulador de Android. No se ejecutan en dispositivos físicos, y la latencia de audio necesita hardware real (F2-16).
- Pendiente: la validación de fixtures contra `contracts/openapi.json` del backend.
- Abierto: la forma de la ruta de datos de la pantalla Hoy. La guía menciona `/v1/progress` sin describir su respuesta, así que el fixture `hoy` aún no se sirve por la API simulada.
- Abierto: en Android, el identificador llega como resource-id. Hay que comprobar en un emulador que un valor con puntos y guiones se localiza tal cual.
