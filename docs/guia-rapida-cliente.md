# GUÍA RÁPIDA · CLIENTE

Para la sesión que programa o diseña el cliente Flutter (interfaz visual, audio en el dispositivo, expediente local). Leer esto primero y nada más; ir a los documentos solo por el ancla indicada. Estado: 16 de noviembre de 2026; el backend modular de M1 está en master 2f51ee0. La guía del servidor es otro archivo: «claude/GUÍA RÁPIDA — backend.md».

## 0. Anclas

- Documento del frontend (fuente de verdad de vistas y diseño): https://claude.ai/artifact/VeovvYek97Ecs7ZzvM2V4a · id del documento: e80752cc-64ed-426b-b915-b495efdd8c87 · cuerpo: 61281643-84fc. Copia en el proyecto: «claude/Frontend — vistas y diseño.md» (del 14 de noviembre; no trae la sección «Vistas de la arquitectura modular», que sí está en el documento vivo y resumida aquí, en la sección 6).
- Maquetas: lienzo de pantallas https://claude.ai/artifact/ScnMR8v3SgGib17MyxQWGz · lienzo del simulacro y del índice https://claude.ai/artifact/KFrLFSt7Tt86UfAvkCdkgw
- Documento de arquitectura: https://claude.ai/artifact/6BA3PkksydBNdTCiXXCTiL · id: 29e8b3ef-0b96-43f0-beff-ea0a4ce7e91d
  - Pestaña principal (cuerpo 78158044-380e): secciones «Cliente Flutter», «Interfaz de usuario», «Contratos y API», «Seguridad, privacidad y cumplimiento».
  - Anexo A, vistas del cliente (cuerpo 5babcbef-203e).
  - Anexo B, simulacro e índice (cuerpo 4a801427-d8a5): datos que muestran las vistas 26 a 28.
  - Anexo D, arquitectura modular (cuerpo 38f23f85-f219): AD-15 (cliente), AD-04 (capacidades y especificación de `sight`), AD-06 (catálogo, permisos y rutas), AD-10 (modelo de negocio).
- Cómo llegar a un ancla: con las herramientas de Docs, buscar el código (por ejemplo «AD-15») o el título de la sección dentro del cuerpo indicado.
- Entregables del cliente: F2-01 a F2-16 en el tracker de la pestaña principal; M2-08 en el Anexo D, AD-12.

## 1. Qué es el cliente

- Flutter (Dart) como base única para escritorio, móvil y web, con Riverpod, go_router y Drift. Web es el canal secundario; el núcleo de audio se construye primero en Windows.
- Es un instrumento de medición, no una aplicación de idiomas: sobrio, denso en datos, tema oscuro principal.
- La lógica de negocio vive en el servidor. El cliente reproduce, graba, mide en local lo que exige el audio y pinta lo que el servidor decide.

## 2. Invariantes (no romper)

1. El audio del usuario nunca sale del dispositivo. Al servidor viaja la parte transportable del expediente: marcas de tiempo, tramos de voz, transcripción y huella de la grabación.
2. El expediente local va cifrado y encadenado por huellas; la sincronización es idempotente.
3. El cliente no decide el acceso ni lleva nombres de módulos: pinta `GET /v1/catalog` y refleja `access.state`.
4. Un reproductor por capacidad, elegido por `config.capability` del turno; ausente significa consecutiva. Capacidad desconocida: estado de actualización obligatoria.
5. La métrica protagonista es la ventana sostenida por dirección, no la calidad Q. La nota manda solo dentro de las vistas del simulacro.
6. Ningún estado depende solo del color. Los colores semánticos son para veredictos del juez y decisiones del motor. El rojo no se usa para grabar.
7. Durante una sesión no hay navegación y el anillo no muestra cifras.
8. Hoy no muestra racha.
9. «Paquete» es el paquete de referencia; lo que se compra se llama «módulo».
10. El índice de preparación se dibuja como rango y dice que no es una probabilidad de aprobar; sin calibración publicada dice «sin calibrar».

## 3. Módulos del cliente

| Módulo | Responsabilidad | Fase |
| --- | --- | --- |
| `app_shell` | Navegación adaptable, temas, rutas | F2 |
| `design_system` | Tokens de color y tipografía, componentes comunes | F2 |
| `api_client` | Cliente generado desde el OpenAPI | F2 |
| `crypto` | Clave por usuario en el almacén seguro; cifrado local | F2 |
| `events_local` | Expediente local en Drift, cadena de huellas, manifiesto | F2 |
| `sync` | Bandeja de salida, reintentos idempotentes, réplica de eventos | F2 |
| `session_channel` | WebSocket de la sesión, reconexión, latido | F2 |
| `audio_core` | Interfaz `AudioEngine`, implementaciones nativa y web | F2 |
| `device_calibration` | Bucle de retorno, piso de ruido, detección de Bluetooth | F2 |
| `local_analysis` | VAD y ASR sobre la grabación, en hilos aparte | F2 |
| `asset_cache` | Descarga por huella, verificación, límite de tamaño | F2 |
| `session_player` | Pantallas de sesión por tipo; se amplía con el reproductor de vista y, después, el de simultánea corta | F2, M2-08, M4-01 |
| `review_room` | Sala de revisión y panel del porqué | F2 |
| `knobs_console` | Consola de perillas con candado | F3 |
| `progress` | Tablero y gráficos | F4 |
| `notebook`, `packs`, `search` | Cuaderno, paquetes de referencia, búsqueda | F4 |
| `settings_privacy` | Consentimientos, retención, exportación y borrado | F2 |
| `catalog` (nuevo) | Catálogo de módulos, detalle, permisos en caché y módulo activo | M2-08 |
| `exam` (nuevo) | Simulacro, resultado e índice: vistas 26 a 28 | M2-08 |
| `institution` (nuevo) | Panel del instructor y constancias | M5 |

## 4. Qué hace el dispositivo y qué hace el servidor

- Dispositivo: flujo dúplex de audio, marca T0, VAD y ASR locales (el ASR depende de la decisión D-01), cifrado local, expediente.
- Servidor: métricas temporales, juez, motor y supervisor, banco, voz del orador, informes, permisos.
- Eventos que emite el dispositivo: SessionStarted, SourcePlaybackEnded, WindowClosed, CaptureRecorded (solo local), CaptureFingerprinted, VadSegmentsDetected, TranscriptProduced, DecisionRated, AdviceRated, ConsentGiven, ConsentWithdrawn. Nuevo: StimulusDisplayed, en la traducción a la vista.
- Eventos que pueden emitir los dos lados: SessionPaused, SessionResumed, SessionFinished, SessionAbandoned, LanguagePairsSet, DeviceCalibrated, ReevaluationRequested, EvaluationSelected, AppealFiled, AppealResolved, AnnotationAdded, KnobLocked, KnobReleased.

## 5. Contrato con el servidor

- REST: `contracts/openapi.json` del repositorio, generado desde los modelos. Canal en vivo: `WS /v1/sessions/{id}/channel`. Sincronización: `POST /v1/events:batch`.
- Rutas que ya existen: autenticación, `/v1/me`, dispositivos y calibraciones, banco, sesiones y turnos, explicación, reevaluaciones, apelaciones, perillas y candados, progreso, cuaderno, paquetes de referencia, plan y repaso, búsqueda, informes, activos de audio.
- Rutas del backend modular, que ya existen en el servidor (M1-04, 16 de noviembre): `GET /v1/catalog`, `GET /v1/catalog/{product_id}`, `GET /v1/me/entitlements`; campo opcional `product` en `POST /v1/sessions` (ausente es la base). Errores: `product_not_found` (404) y `product_not_entitled` (403); el cuerpo de estos dos errores trae además el campo `code`. Los permisos se conceden por rutas del laboratorio (solo administradores), no desde el cliente.
- Tope gratuito (M1-05): sin un permiso vigente de un módulo que incluya la base, la sesión se recorta al crearla, sin error: `max_turns` llega como máximo en 12; además hay 1 sesión por día y 0,30 dólares de gasto por día, y al pasarlos rige el mecanismo de límites que ya existía (SessionLimited, ventana fija con KnobLocked y juicio diferido con JudgingDeferred). El catálogo todavía no devuelve estas cifras: el cliente no debe llevarlas escritas, y si la vista del tope gratuito las necesita hay que sumarlas al contrato del servidor como campo opcional.
- Rutas del simulacro (Anexo B), todavía sin servidor: `/v1/exams/blueprints`, `/v1/exams/forms`, `/v1/exams/attempts/{session_id}`, `/v1/readiness`, `/v1/exams/outcomes`.
- Acceso que devuelve el catálogo por módulo: `free`, `active`, `locked` o `expired`, con su vencimiento.
- Mientras el servidor no tenga las rutas del simulacro, se trabaja con datos simulados que respeten esas formas.

## 6. Vistas

| Rango | Qué son | Estado |
| --- | --- | --- |
| 1 a 25 | Catálogo original: Hoy, selector, calibraciones, reproductor, tarjeta del turno, perillas, paquetes, resumen, sala de revisión, porqué, apelación, historial, expediente, progreso, debilidades, comparación, informe periódico, cuaderno, ajustes, laboratorio, primera ejecución, estados del sistema, tiempo real, cabina | Maquetadas en teléfono y aprobadas el 13 de noviembre; siete también en ancho amplio, pendientes de aprobación |
| 26 a 28 | Resultado del simulacro, índice de preparación, calificación externa, y el retoque de Hoy con el índice | Maquetadas en tres anchos, pendientes de aprobación |
| 29 | Catálogo de módulos | Sin maquetar · M2-08 |
| 30 | Detalle del módulo y acceso | Sin maquetar · M2-08 |
| 31 | Reproductor · traducción a la vista | Sin maquetar · M2-08 |
| 32 | Constancia y horas | Sin maquetar · M5-02 |
| 33 | Panel del instructor | Sin maquetar · M5-01 |

Retoques pendientes de maquetar: Hoy (módulo activo), selector de sesión (módulo, capacidad, simulacro), biblioteca de paquetes (formas del módulo), progreso y debilidades (por capacidad y por tipo de unidad), ajustes («plan y uso» pasa a permisos y vencimientos), estados del sistema (tope gratuito y pase vencido), reproductor de cabina (sirve primero a la simultánea corta).

Reproductor de traducción a la vista, lo que debe cumplir (AD-04): muestra el documento; emite StimulusDisplayed con el instante en que aparece; graba desde ese instante; el texto sigue visible hasta el cierre; cierra con la tecla o al vencer el límite, con WindowClosed; no hay audio de orador ni SourcePlaybackEnded.

## 7. Diseño

- Fondo grafito #0D1012; superficies #161A1E; líneas #2A3138.
- EN→ES turquesa #5AD4C4 (también el acento); ES→EN azul #7DB7FF.
- Veredictos: ámbar #E9C46A parcial; naranja #FF9A57 error mayor u omisión; rojo #FF6F61 error crítico o distorsión.
- Tipografía: Space Grotesk en títulos, Inter en texto, JetBrains Mono en toda cifra.
- Anchos: compacto, menos de 600 px, barra inferior; medio, de 600 a 1024 px, riel angosto; amplio, más de 1024 px, riel con etiquetas.
- Estados de espera sobre el anillo: preparando, reproduciendo, grabando y procesando. Respetan la preferencia de reducir movimiento.
- Navegación: Practicar, Revisar, Progreso, Cuaderno y Perfil.

## 8. Orden de trabajo

1. Tokens y componentes de `design_system` a partir de las maquetas (F2-01).
2. Esqueleto: navegación adaptable, rutas y cliente de API generado (F2-01).
3. Pantallas de F2: Hoy, selector, calibraciones, reproductor, tarjeta del turno, resumen, sala de revisión, porqué, apelación, expediente, ajustes, primera ejecución y estados del sistema.
4. Módulos y simulacro (M2-08): vistas 26 a 31 y sus retoques. Antes hay que maquetar las vistas 29 a 31.
5. Consola de perillas (F3).
6. Progreso, debilidades, comparación, cuaderno, paquetes, historial e informe periódico (F4).

Las pantallas se construyen contra un `AudioEngine` simulado y el contrato OpenAPI, sin esperar al servidor.

## 9. Trampas conocidas

- El módulo `packs` del cliente es de paquetes de referencia; los módulos vendibles van en `catalog`.
- En la traducción a la vista, T0 es el instante en que se muestra el texto; la latencia que se informa es el tiempo de preparación.
- Crear una sesión exige conexión, porque ahí se comprueba el permiso; el catálogo y los permisos se guardan en caché con su vencimiento.
- La compra ocurre fuera de la aplicación en la primera versión; la aplicación solo refleja el permiso al sincronizar.
- Las cifras de las maquetas son ilustrativas.
- Decisiones abiertas que tocan al cliente: D-01 (dónde corre el ASR), D-07 (librería de gráficos: fl_chart, a confirmar), D-11 (nombre del producto), D-20 (cobro y tiendas).
- Maquetas que faltan desde antes: calentamiento, informe de paquete, informe de calibración, subpantallas del laboratorio, ancho medio y tema claro.
