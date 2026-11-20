# Ratchets de calidad y rendimiento

Cada medida de calidad o de rendimiento tiene una regla en `linea-base.json`, y ninguna medida puede empeorar respecto de su línea base.

Hay dos tipos de regla. Un tope es un conteo de defectos, como cadenas de texto escritas directamente en la interfaz o avisos del analizador. Falla si la medida supera el tope más su tolerancia. Un suelo es una puntuación, como la categoría de rendimiento de Lighthouse. Falla si la medida queda por debajo del suelo menos su tolerancia.

La línea base solo se aprieta. Cuando una medida mejora, `actualizar` sube el suelo o baja el tope, en un commit aparte para que la mejora se vea. Cuando empeora, la línea base no se mueve y la regla falla.

Para correr las pruebas de este motor, desde la raíz del repositorio: `python -m pytest calidad/tests`.

Lighthouse ya se mide en el job `lighthouse` de `.github/workflows/interfaz.yml`, sobre la compilación web de la app. `python -m calidad.lighthouse` convierte el informe en medidas de 0 a 100, y `python -m calidad.evaluar --parcial` las compara con la línea base. Esa comparación todavía no tiene reglas: las reglas de Lighthouse se añaden a `linea-base.json` en un commit aparte, con el valor de la primera medición en CI como punto de partida. Hasta entonces el job solo publica las puntuaciones en el resumen.

Las cadenas literales y el analizador siguen sin conectar. Las cadenas necesitan la carpeta `lib/` del proyecto Flutter y el analizador necesita el proyecto. Cada una se añade a `linea-base.json` cuando pueda medirse, con su valor actual como línea base inicial.
