# interprete-cliente

Cliente del **Entrenador de interpretación** (la app que acompaña al backend
`interprete`). Es un cliente Flutter (Dart) pensado como instrumento de
medición, no como una aplicación de idiomas: sobrio, denso en datos y con el
tema oscuro como principal.

> Estado: **documentación, sin código todavía.** Este repositorio reúne, por
> ahora, la documentación de vistas y diseño del frontend. El código del
> cliente aún no está escrito; el orden de trabajo para empezarlo está en
> `docs/guia-rapida-cliente.md` (sección 8) y en `docs/frontend-vistas-y-diseno.md`.

## Qué hay aquí

- `docs/frontend-vistas-y-diseno.md` — fuente de verdad de vistas y diseño:
  decisiones de diseño, catálogo de 25 vistas (más las del simulacro), estados
  de espera, anchos de pantalla y orden de trabajo.
- `docs/anexo-a-vistas-del-cliente.md` — el catálogo de vistas tal como vive en
  el documento de arquitectura (Anexo A), con el lenguaje visual.
- `docs/guia-rapida-cliente.md` — guía rápida para la sesión que programa o
  diseña el cliente: qué es, invariantes, módulos, el contrato con el servidor
  y el orden de trabajo.

## Stack decidido

Flutter (Dart) como base única para escritorio, móvil y web, con Riverpod,
go_router y Drift. El núcleo de audio se construye primero en Windows. La
lógica de negocio vive en el servidor (`interprete`); el cliente reproduce,
graba, mide en local lo que exige el audio y pinta lo que el servidor decide.

## Maquetas

Las maquetas no son archivos de este repositorio; viven en lienzos de Claude:

- Maquetas de pantallas (25 vistas): https://claude.ai/artifact/ScnMR8v3SgGib17MyxQWGz
- Maquetas del simulacro y del índice: https://claude.ai/artifact/KFrLFSt7Tt86UfAvkCdkgw
- Documento del frontend (vivo): https://claude.ai/artifact/VeovvYek97Ecs7ZzvM2V4a
- Documento de arquitectura y tracker: https://claude.ai/artifact/6BA3PkksydBNdTCiXXCTiL
