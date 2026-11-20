# Ratchets de calidad y rendimiento

Cada medida de calidad o de rendimiento tiene una regla en `linea-base.json`, y ninguna medida puede empeorar respecto de su línea base.

Hay dos tipos de regla. Un tope es un conteo de defectos, como cadenas de texto escritas directamente en la interfaz o avisos del analizador. Falla si la medida supera el tope más su tolerancia. Un suelo es una puntuación, como la categoría de rendimiento de Lighthouse. Falla si la medida queda por debajo del suelo menos su tolerancia.

La línea base solo se aprieta. Cuando una medida mejora, `actualizar` sube el suelo o baja el tope, en un commit aparte para que la mejora se vea. Cuando empeora, la línea base no se mueve y la regla falla.

Para correr las pruebas de este motor, desde la raíz del repositorio: `python -m pytest calidad/tests`.

Las medidas reales todavía no están conectadas. Las cadenas literales necesitan la carpeta `lib/` del proyecto Flutter, el analizador necesita el proyecto y Lighthouse necesita una compilación web medible de la app. Cada una se añade a `linea-base.json` cuando pueda medirse, con su valor actual como línea base inicial.
