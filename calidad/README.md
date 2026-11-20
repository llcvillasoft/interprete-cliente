# Ratchets de calidad y rendimiento

Cada medida de calidad o de rendimiento tiene una regla en `linea-base.json`, y ninguna medida puede empeorar respecto de su línea base.

Hay dos tipos de regla. Un tope es un conteo de defectos, como cadenas de texto escritas directamente en la interfaz o avisos del analizador. Falla si la medida supera el tope más su tolerancia. Un suelo es una puntuación, como la categoría de rendimiento de Lighthouse. Falla si la medida queda por debajo del suelo menos su tolerancia.

La línea base solo se aprieta. Cuando una medida mejora, `actualizar` sube el suelo o baja el tope, en un commit aparte para que la mejora se vea. Cuando empeora, la línea base no se mueve y la regla falla.

Para correr las pruebas de este motor, desde la raíz del repositorio: `python -m pytest calidad/tests`.

Lighthouse ya se mide en el job `lighthouse` de `.github/workflows/interfaz.yml`, sobre la compilación web de la app. `python -m calidad.lighthouse` convierte el informe en medidas de 0 a 100 para accesibilidad, buenas prácticas y SEO. El rendimiento de Lighthouse no se mide, porque Flutter web no tiene el Largest Contentful Paint que Lighthouse exige; su lugar lo ocupa `python -m calidad.tamanos`, que mide en kilobytes los JavaScript de arranque de la compilación. `python -m calidad.evaluar --parcial` compara todas las medidas con la línea base. Las reglas de Lighthouse y de tamaño están en `linea-base.json`, con los valores de la primera medición en CI (run 44674219780 de GitHub Actions). El job publica las medidas en el resumen y en el log.

Las cadenas literales se miden con `python -m calidad.literales app/lib/presentacion`: son el texto escrito directamente en el código de la interfaz. La línea base es 19, y el tope baja a medida que los textos salen a recursos externos. El job `ratchets` de `calidad.yml` comprueba el tope en cada PR. Los comentarios de línea completa, las directivas import y los identificadores técnicos de Semantics no cuentan.

El analizador sigue sin conectar: necesita el proyecto Flutter ya compilado para leer sus avisos.
