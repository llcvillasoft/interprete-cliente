# interprete-cliente

Cliente del **Entrenador de interpretación** (la app que acompaña al backend
`interprete`). Es un cliente Flutter (Dart) pensado como instrumento de
medición, no como una aplicación de idiomas: sobrio, denso en datos y con el
tema oscuro como principal.

> Estado: **en construcción.** Ya hay código: la pantalla Hoy, la navegación
> adaptable, el cliente de API, las pruebas de la aplicación, la batería de
> interfaz y los ratchets de calidad. El estado de cada entregable está en
> `docs/frontend-tracker.md`.

## Qué hay aquí

- `docs/frontend-documento-maestro.md` — documento maestro de arquitectura y
  diseño del cliente: invariantes, módulos, reparto con el servidor, catálogo
  de 33 vistas, gráficos, estados de espera y conflictos entre fuentes.
- `docs/frontend-tracker.md` — tracker del cliente: fases, filas de F2, estado
  de maquetas y decisiones que tocan al cliente.
- `docs/frontend-vistas-y-diseno.md` y `docs/guia-rapida-cliente.md` — documentos
  anteriores, que el documento maestro reemplaza.
- `docs/anexo-a-vistas-del-cliente.md` — copia del Anexo A del documento de
  arquitectura: el catálogo de vistas con el lenguaje visual.
- `calidad/`, `pruebas/`, `contrato/` y `.github/workflows/` — ratchets de
  calidad, batería de interfaz, contrato con el servidor y CI.

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
