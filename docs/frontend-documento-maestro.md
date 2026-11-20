# Frontend · documento maestro de arquitectura y diseño

Estado al 20 de noviembre de 2026. Reemplaza a «Frontend — vistas y diseño» (borrada del proyecto el 20 de noviembre) y a «GUÍA RÁPIDA — cliente» (migrada aquí el 20 de noviembre). Su tracker es «Frontend — tracker».

Fuentes consolidadas: el documento vivo del frontend en Claude Docs (revisión 17, con la sección «Vistas de la arquitectura modular»); el documento de arquitectura y tracker, pestaña principal (revisión 173, con las secciones «Cliente Flutter», «Interfaz de usuario», «Reportes y gráficos» y «Seguridad, privacidad y retención»); el Anexo D (AD-04, AD-05, AD-06, AD-10 y AD-15); el Anexo B; y la guía rápida del cliente (16 de noviembre), cuyas anclas, invariantes, trampas y orden se cotejaron con este documento el 20 de noviembre. Cuando dos fuentes chocan, la sección 14 lo dice.

## 1. Anclas

- Documento del frontend (fuente de verdad de vistas y diseño): https://claude.ai/artifact/VeovvYek97Ecs7ZzvM2V4a · id e80752cc-64ed-426b-b915-b495efdd8c87 · cuerpo 61281643-84fc.
- Documento de arquitectura y tracker: https://claude.ai/artifact/6BA3PkksydBNdTCiXXCTiL · id 29e8b3ef-0b96-43f0-beff-ea0a4ce7e91d.
  - Pestaña principal (cuerpo 78158044-380e): secciones «Cliente Flutter», «Interfaz de usuario», «Contratos y API» y «Seguridad, privacidad y cumplimiento».
  - Anexo A, vistas del cliente: cuerpo 5babcbef-203e.
  - Anexo B, simulacro e índice: cuerpo 4a801427-d8a5 (datos que muestran las vistas 26 a 28).
  - Anexo D, arquitectura modular: cuerpo 38f23f85-f219. AD-15: https://claude.ai/artifact/6BA3PkksydBNdTCiXXCTiL#9911562e-099d.
- Maquetas de pantallas: https://claude.ai/artifact/ScnMR8v3SgGib17MyxQWGz. Maquetas del simulacro y del índice: https://claude.ai/artifact/KFrLFSt7Tt86UfAvkCdkgw.
- Repositorio del cliente: `llcvillasoft/interprete-cliente` (GitHub, privado). Contiene la documentación de vistas y diseño (commit 31068fd), la pantalla Hoy, la navegación adaptable, el cliente de API y las puertas de calidad.
- Cómo llegar a un ancla: con las herramientas de Docs, buscar el código (por ejemplo «AD-15») o el título de la sección dentro del cuerpo indicado.
- Entregables del cliente: F2-01 a F2-16 en la pestaña principal, sección «Tracker» (copia en «Frontend — tracker»); M2-08 en el Anexo D, AD-12.

Las cifras de las maquetas son ilustrativas.

## 2. Invariantes

Son diez. Ninguna sesión de trabajo las rompe; una excepción se decide con Alejandro y se anota aquí.

1. El audio del usuario nunca sale del dispositivo. Al servidor viaja la parte transportable del expediente: marcas de tiempo, tramos de voz, transcripción y huella de la grabación. Los veredictos bajan del servidor y se guardan en el expediente local.
2. El expediente local va cifrado y encadenado por huellas. La sincronización es idempotente.
3. El cliente no decide el acceso ni lleva nombres de módulos. Pinta lo que devuelve `GET /v1/catalog` y refleja `access.state`.
4. Hay un reproductor por capacidad, elegido por `config.capability` del turno. Si el campo falta, la capacidad es consecutiva. Una capacidad que el cliente no conoce muestra el estado de actualización obligatoria.
5. La métrica protagonista es la ventana sostenida por dirección, no la calidad Q. La nota manda solo dentro de las vistas del simulacro.
6. Ningún estado depende solo del color. Los colores semánticos son para veredictos del juez y decisiones del motor. El rojo no se usa para grabar.
7. Durante una sesión no hay navegación y el anillo no muestra cifras.
8. Hoy no muestra racha: mide constancia, no competencia.
9. «Paquete» es el paquete de referencia; lo que se compra se llama «módulo».
10. El índice de preparación se dibuja como rango y dice que no es una probabilidad de aprobar. Sin calibración publicada dice «sin calibrar».

## 3. Principios de diseño

La aplicación es un instrumento de medición, no una aplicación de idiomas: sobria, densa en datos y con el tema oscuro como principal.

| Elemento | Decisión |
| --- | --- |
| Fondo y superficies | Grafito #0D1012; superficies #161A1E; líneas #2A3138 |
| Dirección EN→ES | Turquesa #5AD4C4, que es también el acento de la aplicación |
| Dirección ES→EN | Azul #7DB7FF |
| Veredictos | Ámbar #E9C46A parcial; naranja #FF9A57 error mayor u omisión; rojo #FF6F61 error crítico o distorsión |
| Tipografía | Space Grotesk en títulos; Inter en texto; JetBrains Mono en toda cifra |
| Formatos de maqueta | Teléfono 390 × 844; medio 834 px; amplio 1440 px. Qué vista usa cada formato: secciones 5 y 11 |
| Idioma | Español formal con tú en todos los textos |

Reglas que acompañan la tabla:

- Cada veredicto lleva además una forma o un subrayado propio.
- Los colores semánticos se reservan para veredictos del juez y decisiones del motor; no se usan como decoración.
- Las animaciones respetan la preferencia de reducir movimiento del sistema: en ese caso el anillo cambia de estado sin moverse.

### La métrica protagonista

Es la ventana que el usuario sostiene (el factor f por dirección), no la calidad Q. Con un motor adaptativo, Q se mantiene más o menos constante por diseño, porque el motor aprieta cuando el usuario rinde bien; un gráfico de Q en el tiempo sale plano. El progreso real se ve en la dificultad sostenida: una ventana que se encoge hacia el tiempo real del usuario, es decir, el piso 1.1 × ρ. Q se reserva para el paquete de referencia, el único instrumento honesto de comparación.

### Lo auditable

Para que el usuario vuelva a ver en qué falló y por qué, hay cuatro vistas encadenadas: sala de revisión, panel del porqué, apelación y expediente. El expediente tiene vista propia y acceso desde la pantalla inicial. El recorrido de un turno que cierra se describe en la sección 7.3.

## 4. Arquitectura del cliente

### 4.1 Base

- Una sola base Flutter para web, escritorio y móvil, con Riverpod para el estado, go_router para la navegación y Drift sobre SQLite para el expediente local. En web, el expediente usa SQLite en WebAssembly.
- La lógica de negocio vive en el servidor. El cliente reproduce, graba, mide en local lo que exige el audio y pinta lo que el servidor decide.
- Web es el canal secundario. El núcleo de audio se construye primero en Windows (F2-02).

### 4.2 Módulos del cliente

| Módulo | Responsabilidad | Fase |
| --- | --- | --- |
| `app_shell` | Navegación adaptable, temas claro y oscuro, rutas | F2 |
| `design_system` | Tokens de color y tipografía, componentes comunes | F2 |
| `api_client` | Cliente generado desde el OpenAPI | F2 |
| `crypto` | Clave por usuario en el almacén seguro del sistema; cifrado de audio y de contenido personal | F2 |
| `events_local` | Expediente local en Drift, encadenado de huellas, manifiesto | F2 |
| `sync` | Bandeja de salida, reintentos idempotentes, réplica de eventos del servidor | F2 |
| `session_channel` | WebSocket de la sesión, reconexión, latido | F2 |
| `audio_core` | Interfaz `AudioEngine` con implementaciones nativa y web | F2 |
| `device_calibration` | Bucle de retorno, piso de ruido, detección de Bluetooth | F2 |
| `local_analysis` | VAD y ASR sobre la grabación guardada, en hilos aparte | F2 |
| `asset_cache` | Descarga por huella, verificación, límite de tamaño | F2 |
| `session_player` | Pantallas de sesión por capacidad; después, el reproductor de vista (M2-08) y el de simultánea corta (M4-01) | F2, M2-08, M4-01 |
| `review_room` | Sala de revisión y panel del porqué | F2 |
| `knobs_console` | Consola de perillas con candado | F3 |
| `progress` | Tablero y gráficos | F4 |
| `notebook`, `packs`, `search` | Cuaderno, paquetes de referencia, búsqueda | F4 |
| `settings_privacy` | Consentimientos, retención, exportación y borrado | F2 |
| `catalog` (nuevo) | Catálogo de módulos, detalle, permisos en caché y módulo activo | M2-08 |
| `exam` (nuevo) | Simulacro, resultado e índice: vistas 26 a 28 | M2-08 |
| `institution` (nuevo) | Panel del instructor y constancias | M5 |

`packs` es de paquetes de referencia; los módulos vendibles van en `catalog`.

Cada módulo de pantalla depende de interfaces, nunca de implementaciones nativas, para poder probarse con un `AudioEngine` falso.

### 4.3 Reglas de arquitectura del cliente (AD-15)

1. Sin nombres de módulos en el código. Títulos, capacidades, cobertura y estado de acceso vienen de `GET /v1/catalog`.
2. El acceso lo decide el servidor. El cliente refleja `access.state`, que puede ser `free`, `active`, `locked` o `expired`, con su vencimiento. Un error `product_not_entitled` lleva al detalle del módulo.
3. Un reproductor por capacidad. Todos comparten controles, anillo y estados de espera.
4. Módulo activo: estado global y persistente, con la base por omisión. Hoy, el selector de sesión, progreso y cuaderno se filtran por él.
5. Sin conexión: el catálogo y los permisos se guardan en caché con su vencimiento. Crear una sesión exige conexión, porque ahí se comprueba el permiso.
6. Compra: en la primera versión ocurre fuera de la aplicación. La aplicación refleja el permiso al sincronizar.
7. El reproductor de vista emite StimulusDisplayed al mostrar el texto. El resto del expediente local no cambia.

### 4.4 Núcleo de audio

- El núcleo es miniaudio por FFI: WASAPI en Windows y Web Audio con AudioWorklet en web. Un solo flujo dúplex por plataforma, equivalente al del POC.
- La marca T0 se calcula en código nativo con precisión de muestra, sin pasar por el recolector de basura de Dart.
- `AudioEngine` expone el flujo dúplex, la reproducción programada de un buffer, el contador de muestras, la captura por bloques, las latencias de entrada y salida, y el cierre limpio.
- La precisión en web depende del navegador. Cada turno registra su plataforma y su ruta de audio, para que las comparaciones de progreso no mezclen mediciones de distinta calidad.
- La matriz de dispositivos de referencia que se propone es: el equipo Windows del POC, un Mac, un iPhone, una tableta y dos Android de gamas distintas (F2-16). Un dispositivo fuera de la matriz se acepta si pasa su calibración.
- Para iOS y Android, la latencia varía mucho según el modelo; por eso la calibración del dispositivo es obligatoria (F2-03, F2-05).

### 4.5 Análisis local, sin conexión y cifrado

- VAD: Silero en ONNX Runtime, como en el POC. Corre sobre la grabación guardada, tras cerrar la captura. La implementación en el cliente se confirma en F2-06.
- ASR: el POC usa faster-whisper. El documento de arquitectura propone whisper.cpp por FFI en el dispositivo, con el modelo elegido según la capacidad del equipo. La decisión es D-01 y la resuelve la prueba de sensibilidad del POC más una prueba en móvil (F2-07).
- Ambos corren mientras suena el segmento siguiente, con prioridad baja para no interferir con el hilo de audio.
- Sin conexión, la sesión solo puede usar ventana fija sobre ítems y paquetes ya descargados. VAD y ASR corren igual; el juez y el motor esperan a la reconexión, y el turno queda marcado como analizado más tarde.
- Cifrado: una clave por usuario guardada en el almacén seguro del sistema (Keychain en iOS y macOS, Keystore en Android, el almacén de credenciales de Windows, el llavero en Linux). En web, la clave vive en el almacenamiento del navegador con WebCrypto.

### 4.6 Reparto con el servidor

- El dispositivo hace lo que exige estar junto al audio: flujo dúplex, marca T0, VAD y ASR locales, cifrado y expediente local.
- El servidor hace lo que exige claves, modelos grandes o la vista de toda la historia: métricas temporales, juez, motor y supervisor, banco, voz del orador, informes y permisos.
- Eventos que emite el dispositivo: SessionStarted, SourcePlaybackEnded, WindowClosed, CaptureRecorded (solo local), CaptureFingerprinted, VadSegmentsDetected, TranscriptProduced, DecisionRated, AdviceRated, ConsentGiven, ConsentWithdrawn y, nuevo, StimulusDisplayed.
- Eventos que pueden emitir los dos lados: SessionPaused, SessionResumed, SessionFinished, SessionAbandoned, LanguagePairsSet, DeviceCalibrated, ReevaluationRequested, EvaluationSelected, AppealFiled, AppealResolved, AnnotationAdded, KnobLocked y KnobReleased.

### 4.7 Contrato con el servidor

- REST: `contracts/openapi.json` del repositorio del backend, generado desde los modelos. El cliente Dart se genera de ese OpenAPI.
- Canal en vivo: `WS /v1/sessions/{id}/channel`. Mensajes: hello, welcome, clock.ping y clock.pong, TurnScheduled, SourcePlaybackEnded, WindowClosed, CaptureFingerprinted, VadSegmentsDetected, TranscriptProduced, SupervisorDecided, turn.feedback (entrenamiento), turn.advance, session.pause, session.resume, session.abort, SessionReportGenerated y error. Cada mensaje lleva `turn_id` y `origin_seq`; un mensaje repetido se ignora.
- Sincronización de eventos del dispositivo: `POST /v1/events:batch`.
- Rutas que ya existen: `POST /v1/auth/token`, `GET /v1/me`, `DELETE /v1/me`, `POST /v1/devices`, `POST /v1/devices/{id}/calibrations`, `GET /v1/bank/items`, `GET /v1/assets/{sha256}`, `POST /v1/sessions`, `GET /v1/sessions`, `GET /v1/sessions/{id}`, `GET /v1/events`, `GET /v1/turns/{id}/explanation`, `POST /v1/turns/{id}/reevaluations`, `PUT /v1/turns/{id}/current-evaluation`, `POST /v1/turns/{id}/appeals`, `GET /v1/reports/{session_id}`, `POST /v1/exports`, `GET /v1/axes` y `PUT /v1/axes/{axis}/{direction}/lock`, `GET /v1/packs` y `GET /v1/packs/{id}`, `GET /v1/progress`, `GET /v1/notebook`, `GET /v1/search`, `GET /v1/exams/blueprints` y `GET /v1/exams/forms`.
- Rutas del módulo de catálogo y permisos, ya implementadas en el servidor: `GET /v1/catalog`, `GET /v1/catalog/{product_id}`, `GET /v1/me/entitlements`, y el campo opcional `product` en `POST /v1/sessions` (ausente equivale a la base). Los permisos los concede un administrador por las rutas del laboratorio; el cliente no concede permisos.
- Errores de permiso: `product_not_found` (404) y `product_not_entitled` (403), ambos con el campo `code`.
- Tope gratuito: sin un permiso vigente que incluya la base, la sesión se recorta al crearla, sin error. `max_turns` llega como máximo en 12. Además hay 1 sesión por día y 0,30 dólares de gasto diario en el juez; al pasarlos rige el mecanismo de límites que ya existía: SessionLimited, ventana fija con KnobLocked y juicio diferido con JudgingDeferred. El catálogo todavía no devuelve esas cifras; el cliente no debe escribirlas. Si la vista del tope las necesita, se suman al contrato como campo opcional.
- Rutas del simulacro (Anexo B), todavía sin servidor: `GET /v1/exams/attempts/{session_id}`, `GET /v1/readiness` y `POST /v1/exams/outcomes`. Mientras tanto se trabaja con datos simulados que respeten esas formas.

## 5. Navegación y formatos de maqueta

La navegación propuesta tiene cuatro destinos (Practicar, Revisar, Progreso y Cuaderno) más Perfil. Las fuentes no fijan la forma exacta de la navegación en cada formato; eso se decide al implementar.

| Formato | Ancho de maqueta | Navegación propuesta | Estado de maquetas |
| --- | --- | --- | --- |
| Teléfono | 390 px | Barra inferior | Vistas 1 a 25 maquetadas y aprobadas el 13 de noviembre; vistas 26 a 28 con lámina de teléfono (M), aprobadas el 20 de noviembre |
| Medio | 834 px | Riel lateral angosto (por confirmar) | Sin láminas confirmadas; la lámina principal de las vistas 26 a 28 podría ser de este ancho (por confirmar) |
| Amplio | 1440 px | Riel lateral con etiquetas | Siete vistas de la sección 11 y las vistas 26 a 28 (lámina W), aprobadas el 20 de noviembre |

Los puntos de corte entre formatos no están confirmados (sección 14).

Durante una sesión desaparece toda la navegación, en cualquier formato.

## 6. Catálogo de vistas

Son 33 vistas. Las 1 a 25 son del catálogo original; las 26 a 28 son del módulo `exam`; las 29 a 33 son de la arquitectura modular.

| N.º | Vista | Destino | Qué muestra | Fase | Origen o estado |
| --- | --- | --- | --- | --- | --- |
| 1 | Hoy | Practicar | Ventana sostenida por dirección con tendencia y distancia al tiempo real; sesión recomendada; pendiente de revisar; eje más débil; acceso al expediente | F2 | Maquetada en teléfono y aprobada el 13 de noviembre. Retoque pendiente (sección 10.1) |
| 2 | Selector de sesión | Practicar | Tipo, direcciones, agresividad, ejes activos | F2 | Aprobada el 13 de noviembre |
| 3 | Calibración del dispositivo | Practicar | Bucle de retorno, latencia, dispersión, piso de ruido, veredicto | F2 | Aprobada el 13 de noviembre |
| 4 | Calibración del usuario | Practicar | Progreso por dirección, ρ, piso, inicio y techo de f | F2 | Aprobada el 13 de noviembre |
| 5 | Reproductor de sesión | Practicar | Estado, anillo de la ventana sin cifras, nivel del micrófono, adelantar | F2 | Aprobada el 13 de noviembre |
| 6 | Tarjeta del turno | Practicar | Arranque, margen, Q, notas por eje, unidades, decisión del motor y su valoración | F2 | Aprobada el 13 de noviembre |
| 7 | Consola de perillas | Practicar | Un deslizador vertical por eje; nivel actual, destino, candado, frase del supervisor | F3 | Aprobada el 13 de noviembre |
| 8 | Biblioteca de paquetes | Practicar | Paquetes, intentos con su Q, comparar, nuevo intento | F4 | Aprobada el 13 de noviembre. Retoque pendiente |
| 9 | Resumen de sesión | Revisar | Trayectoria de f con sondeos, informe, turnos a revisar | F2 | Aprobada el 13 de noviembre |
| 10 | Sala de revisión | Revisar | Ondas alineadas con T0, fin y W; rendición coloreada por estado; unidades del original; repetir VAD | F2 | Aprobada el 13 de noviembre |
| 11 | Panel del porqué | Revisar | Nota del eje, evidencia original contra rendición, justificación, reglas activadas, versiones con que se evaluó | F2 | Aprobada el 13 de noviembre |
| 12 | Apelación | Revisar | Causa, comentario, estado del segundo juicio, evaluación vigente | F2 | Aprobada el 13 de noviembre |
| 13 | Historial | Revisar | Búsqueda en rendiciones, filtros, lista de sesiones | F4 | Aprobada el 13 de noviembre |
| 14 | Expediente | Revisar | Estado de la cadena de huellas; lo guardado; evaluaciones de un turno comparadas con la vigente; reevaluar, verificar, exportar | F2 | Nueva |
| 15 | Tablero de progreso | Progreso | Ventana sostenida contra el tiempo real; arranque; mensaje que llega; Q; paquete | F4 | Aprobada el 13 de noviembre |
| 16 | Mapa de debilidades | Progreso | Mapa de calor de ejes de la rúbrica por tema; datos duros por tipo | F4 | Aprobada el 13 de noviembre |
| 17 | Comparación contra sí mismo | Progreso | Intentos de un paquete, métrica por métrica; A/B de audio; unidad por unidad | F4 | Aprobada el 13 de noviembre |
| 18 | Informe periódico | Progreso | Calendario de práctica; lo que avanzó; errores que se repiten; plan sugerido | F4 | Nueva; antes figuraba solo como reporte |
| 19 | Cuaderno de errores | Cuaderno | Tarjetas que vencen hoy; repaso; tarjetas por error, cifra, unidad o término | F4 | Aprobada el 13 de noviembre |
| 20 | Ajustes y privacidad | Perfil | Qué viaja y qué no; retención; consentimientos; dispositivos; calibración; plan y uso; borrado | F2 | Aprobada el 13 de noviembre. Retoque pendiente |
| 21 | Laboratorio | Perfil (administrador) | Pruebas del juez candidato; apelaciones por resolver; costo por sesión; golden set | F1 | Aprobada el 13 de noviembre. Subpantallas pendientes |
| 22 | Primera ejecución | Fuera de la navegación | Qué es; pasos de preparación; inicio de sesión | F2 | Nueva |
| 23 | Estados del sistema | Sobre cualquier pantalla | Sin conexión; envío del expediente; tope del día; actualización obligatoria; dispositivos | F2 | Nueva. Retoque pendiente |
| 24 | Reproductor · tiempo real | Practicar | Las dos partes del diálogo; anillo en estado de escucha | F5 | Variante del reproductor |
| 25 | Reproductor · cabina | Practicar | Ondas del orador y del usuario; desfase con su zona cómoda | F6 | Variante del reproductor |
| 26 | Resultado del simulacro | Revisar | Nota por dirección contra el umbral; unidades de información; datos duros y errores críticos aparte; ítems a revisar; validez del intento | F4-12 | Maquetada con láminas Main, M y W; aprobada el 20 de noviembre |
| 27 | Índice de preparación | Progreso | Estado; rango por dirección frente al umbral; intentos que lo sostienen; cobertura y calibración externa | F4-13 | Maquetada con láminas Main, M y W; aprobada el 20 de noviembre |
| 28 | Calificación externa | Perfil (administrador) | Cola a ciegas; turno con original y rendición; estado por unidad; juicio global; acuerdo con el juez | F4-14 | Maquetada con láminas Main, M y W; aprobada el 20 de noviembre |
| 29 | Catálogo de módulos | Practicar | Módulos con su acceso (gratuito, activo, bloqueado o vencido), cobertura declarada y estado de calibración | M2-08 | Sin maquetar |
| 30 | Detalle del módulo y acceso | Practicar | Qué incluye, capacidades, formato, cobertura, aviso de no afiliación, vencimiento del pase y cómo obtenerlo | M2-08 | Sin maquetar |
| 31 | Reproductor · traducción a la vista | Practicar | El documento, el anillo del tiempo sin cifras y el nivel del micrófono | M2-08 | Sin maquetar |
| 32 | Constancia y horas | Progreso | Horas cumplidas por módulo de educación continua y la constancia | M5-02 | Sin maquetar |
| 33 | Panel del instructor | Perfil | Cohortes, formas asignadas y resultados por estudiante, sin audio | M5-01 | Sin maquetar |

Notas sobre el catálogo:

- La fase de las vistas 26 a 28 sigue la numeración del Anexo B: F4-12 es la nota del intento, F4-13 el índice y F4-14 el registro de calibración.
- Las láminas Main, M y W son el nombre de cada lámina en el documento vivo: la principal, la de teléfono y la de ancho amplio. Qué ancho exacto tiene Main no está confirmado.
- La tabla de pantallas del documento de arquitectura todavía lista la vista Hoy con racha y última sesión. Esta sección y la vista 1 mandan.
- Las cifras de las maquetas son ilustrativas.

## 7. Vistas clave

Cuatro grupos de vistas definen el producto; el resto deriva de ellas.

### 7.1 Hoy

- Figura central: la ventana sostenida por dirección, EN→ES y ES→EN lado a lado, con su tendencia y la distancia que falta hasta el tiempo real.
- Sesión recomendada con un solo botón para empezar.
- Pendiente de revisar: turnos con error crítico sin abrir, apelaciones en curso y tarjetas de repaso que vencen hoy.
- Eje más débil de la semana, con acceso directo a su evidencia.
- Estado del expediente (íntegro, turnos guardados) con acceso a su vista.
- Sin racha y sin última sesión.
- Con un módulo de examen activo, el índice de preparación aparece como segunda figura (retoque de la vista 1).

### 7.2 Reproductores de sesión

Los tres comparten controles y disposición.

- Consecutiva: anillo de la ventana sin cifras, estado y nivel del micrófono.
- Tiempo real: añade las dos partes del diálogo y pone el anillo en estado de escucha.
- Cabina: sustituye el anillo por las ondas del orador y del usuario, con el desfase y su zona cómoda.
- Traducción a la vista: se describe en la sección 10.3.

El reproductor de consecutiva está casi vacío a propósito: el anillo muestra el avance de la ventana sin cifras, para no inducir a mirar el reloj en lugar de interpretar.

### 7.3 La cadena de auditoría

Las maquetas cuentan una sola historia con el mismo turno, para probar que el recorrido cierra:

1. Sala de revisión: las ondas alineadas y la rendición coloreada muestran una cifra marcada como distorsionada.
2. Panel del porqué: la nota del eje, la evidencia (original contra lo dicho), las reglas que activó el motor y las versiones con que se evaluó.
3. Apelación: el usuario alega error de transcripción, y un segundo juicio le da la razón.
4. Expediente: las dos evaluaciones quedan guardadas, con la vigente señalada y el eje que cambió.

### 7.4 Progreso

El gráfico principal es la ventana sostenida en el tiempo contra la línea del tiempo real. Debajo van cuatro indicadores: arranque, porcentaje del mensaje que llega, Q (marcada como estable por diseño) y el último paquete de referencia. El mapa de debilidades cruza ejes de la rúbrica con temas. La comparación contra sí mismo superpone los intentos de un paquete con A/B de audio.

## 8. Gráficos y reportes

Cada gráfico responde una pregunta concreta del usuario y se alimenta de una proyección, nunca de consultas sobre eventos crudos. Todos muestran qué versión de evaluación usan y separan las mediciones de web de las nativas.

| Gráfico | Pregunta que responde | Forma | Ámbito | Fase |
| --- | --- | --- | --- | --- |
| Trayectoria de f | ¿Cómo se movió la ventana en esta sesión? | Escalones por dirección, sondeos marcados | Sesión | F2 |
| Latencia de arranque | ¿Arranco más rápido que antes? | Mediana por sesión con banda entre cuartiles | Historial | F4 |
| Calidad Q | ¿Mi calidad sube? | Línea por dirección con banda entre cuartiles | Historial | F4 |
| Q contra dificultad | ¿Dónde está mi zona de desarrollo? | Dispersión con la zona objetivo sombreada | Historial | F4 |
| Notas por eje | ¿Qué eje es mi punto débil? | Barras por eje, período actual contra el anterior | Período | F4 |
| Nivel por eje del motor | ¿Cuánto avancé en cada eje? | Pequeños múltiplos, una línea por eje y dirección | Historial | F4 |
| Errores por tipo y severidad | ¿Qué errores cometo y cuánto pesan? | Barras apiladas por semana | Historial | F4 |
| Unidades de información | ¿Cuánto del mensaje llega? | Barras al 100 %: transmitidas, parciales, omitidas, distorsionadas | Sesión e historial | F4 |
| Datos duros | ¿Fallo más en cifras, nombres o fechas? | Barras de exactitud por tipo de dato | Período | F4 |
| Margen y desbordes | ¿Me sobra o me falta ventana? | Histograma del margen M | Período | F4 |
| Paquete de referencia | ¿Mejoré sobre el mismo estímulo? | Puntos por intento, una serie por métrica | Paquete | F4 |
| Mapa de debilidades | ¿En qué tema fallo y en qué eje? | Mapa de calor de ejes por tema o dominio | Historial | F4 |
| Calendario de práctica | ¿Practico con constancia? | Mapa de calor por día | Historial | F4 |
| Costo | ¿Cuánto cuesta cada sesión? | Barras por sesión, juez e informe por separado | Laboratorio | F1 |

Reportes:

| Reporte | Cuándo | Contenido | Formato |
| --- | --- | --- | --- |
| Tarjeta del turno | Tras cada turno en entrenamiento | Métricas, notas por eje, unidades, errores, consejo, decisión del motor | Pantalla |
| Informe de sesión | Al cerrar cada sesión | Evaluación global, patrones entre turnos, debilidades, recomendación, perfil del eje por dirección | Pantalla y PDF |
| Informe de paquete | Tras cada intento de un paquete | Comparación métrica por métrica y unidad por unidad con intentos previos | Pantalla y PDF |
| Informe periódico | Semanal y mensual | Tendencias, ejes que avanzaron, errores recurrentes, plan sugerido | Pantalla y PDF |
| Informe de calibración | Tras cada calibración | Dispositivo: latencias y veredicto; usuario: ρ y límites | Pantalla |
| Informe del laboratorio | Tras cada prueba del juez o del motor | Correlación, detección de sembrados, consistencia, comparación de versiones | Pantalla, solo administrador |
| Exportación completa | A pedido | Todos los eventos transportables y, si el usuario lo elige, su audio local | JSON y archivos |

## 9. Estados de espera

Las cuatro esperas de una sesión se diseñan como una sola familia de animaciones sobre el anillo del reproductor. Preparando, Reproduciendo y Procesando tienen lámina propia; Grabando es el reproductor de sesión. Requisito registrado el 13 de noviembre; maquetado el 14 de noviembre; aprobado el 20 de noviembre.

| Estado | Cuándo ocurre | Indicador |
| --- | --- | --- |
| Preparando | El servidor arranca, la sesión se crea y el audio se descarga | Anillo de trazo segmentado que gira despacio; debajo, los pasos reales (conectando, descargando audio, verificando calibración) que se marcan al cumplirse |
| Reproduciendo | Suena el orador | Anillo en el color de la dirección que late con la amplitud del audio; texto «Escucha» |
| Grabando | Ventana abierta; el usuario interpreta | Anillo que se consume sin cifras y barras del micrófono que responden a la voz; es el estado con menos movimiento |
| Procesando | VAD, transcripción, juez y motor | Anillo indeterminado con las etapas reales que se marcan (detectando voz, transcribiendo, evaluando, decidiendo) |

- En entrenamiento, Procesando ocupa la pantalla entre el turno y su tarjeta. En sesión continua corre en segundo plano mientras suena el segmento siguiente y aparece solo al final, como contador de turnos por evaluar.
- El rojo no se usa para grabar: queda reservado para errores críticos.

## 10. Vistas de la arquitectura modular

La arquitectura modular, decidida el 15 de noviembre, suma las vistas 29 a 33 y retoca varias. Todas están sin maquetar; las 29 a 31 son las siguientes en el orden de trabajo.

### 10.1 Retoques a vistas existentes

| N.º | Vista | Retoque | Etapa |
| --- | --- | --- | --- |
| 1 | Hoy | Módulo activo y, si es de examen, su índice como segunda figura | M2-08 |
| 2 | Selector de sesión | Módulo, capacidad y entrada al simulacro | M2-08 |
| 8 | Biblioteca de paquetes | Formas del módulo activo, separadas de los paquetes de referencia | M2-08 |
| 15 y 16 | Progreso y mapa de debilidades | Series por capacidad y precisión por tipo de unidad | M2-06 |
| 20 | Ajustes y privacidad | «Plan y uso» pasa a mostrar permisos, vencimientos y el tope gratuito | M2-08 |
| 23 | Estados del sistema | Tope gratuito alcanzado, con entrada al catálogo; pase vencido | M2-08 |
| 25 | Reproductor · cabina | Sirve primero a la simultánea corta del módulo CHI | M4-01 |

### 10.2 Reglas de diseño

- El cliente no lleva nombres de módulos: pinta lo que devuelve el catálogo del servidor.
- Hay un reproductor por capacidad, y todos comparten controles, anillo y estados de espera.
- El módulo activo es un estado global: Hoy, el selector, progreso y cuaderno se filtran por él.
- «Paquete» sigue siendo el paquete de referencia; lo que se compra se llama «módulo».
- La métrica protagonista no cambia: la ventana sostenida en Hoy y en Progreso; la nota solo dentro del simulacro.

### 10.3 Reproductor de traducción a la vista (vista 31)

Reglas de AD-04 que la vista debe cumplir:

- Muestra el documento y emite StimulusDisplayed con el instante en que aparece. T0 es ese instante, no el fin del audio.
- Graba desde ese instante. El texto sigue visible hasta el cierre.
- Cierra con la tecla o al vencer el límite, con WindowClosed. No hay audio de orador ni SourcePlaybackEnded.
- La latencia que se informa es el tiempo de preparación hasta la primera voz.

## 11. Anchos amplios

Las 25 vistas originales están maquetadas en teléfono; siete de ellas también en ancho amplio (1440 px). Las vistas 26 a 28 tienen lámina de ancho amplio (W). Las láminas de ancho medio (834 px) no están confirmadas.

| Vista en ancho amplio | Qué cambia frente al teléfono |
| --- | --- |
| Hoy | Dos columnas: la ventana sostenida con su gráfico a la izquierda; sesión recomendada, pendientes y semana a la derecha |
| Sala de revisión | Panel del porqué fijo a la derecha; arriba, los 16 turnos de la sesión con los que tienen error marcados |
| Consola de perillas | Las dos direcciones a la vez, como mesa de mezclas; debajo, los movimientos del supervisor |
| Tablero de progreso | Gráfico principal a todo el ancho; cuatro indicadores; notas por eje contra el período anterior; unidades por semana |
| Historial | Lista de sesiones a la izquierda y detalle a la derecha, con la tabla de turnos |
| Expediente | Eventos del turno en orden, con origen, alcance y huella; a la derecha, evaluaciones y manifiesto |
| Laboratorio | Pruebas del juez, apelaciones y costo en tres columnas; debajo, la simulación contrafactual turno por turno |

El reproductor no cambia: queda centrado. En teléfono, la sala de revisión apila ondas y transcripción; en tableta y escritorio, las muestra lado a lado con el panel del porqué fijo a la derecha.

Las vistas del simulacro (26 a 28) tienen lámina de amplio (W). En ese ancho, la calificación externa deja la cola fija a la izquierda, el turno al centro y el acuerdo a la derecha.

## 12. Orden de trabajo propuesto

Esta secuencia es propuesta; las fuentes no la fijan. El frontend avanza en paralelo al backend. Las pantallas se construyen contra un `AudioEngine` simulado y el contrato OpenAPI, sin esperar a que el servidor esté terminado.

1. Tokens y componentes de `design_system` a partir de las maquetas (F2-01).
2. Esqueleto del cliente: navegación adaptable, rutas y cliente de API generado (F2-01).
3. Pantallas de F2: Hoy, selector, calibraciones, reproductor, tarjeta del turno, resumen, sala de revisión, panel del porqué, apelación, expediente, ajustes, primera ejecución y estados del sistema.
4. Consola de perillas (F3). El candado ya existe en el backend (F3-07).
5. Progreso, mapa de debilidades, comparación, cuaderno, paquetes, historial e informe periódico (F4).
6. Módulos y simulacro (M2-08): primero maquetar las vistas 29 a 31; después integrar las vistas 26 a 28 y los retoques de la sección 10.1.

## 13. Pendientes de diseño

- Confirmar el ancho medio (834 px) y diseñarlo para las vistas que no lo tienen.
- Maquetar: calentamiento; informe de paquete; informe de calibración; subpantallas del laboratorio (golden set y simulación contrafactual); vistas 29 a 33; retoques de la sección 10.1.
- Tema claro: el módulo `app_shell` lo prevé y las maquetas solo cubren el oscuro.
- Nombre del producto (D-11): la primera ejecución lleva un marcador.
- Librería de gráficos (D-07): fl_chart para los gráficos y CustomPainter para las ondas, a confirmar con una prueba en F4 (F4-02).
- Actualizar la fila de Hoy en la tabla de pantallas del documento de arquitectura, o retirar esa tabla y remitir a este documento.

## 14. Conflictos entre fuentes

- Hoy: la tabla de pantallas del documento de arquitectura incluye racha y última sesión; el documento del frontend y la guía del cliente dicen que no. Manda el frontend.
- Aprobación de las vistas: la guía del cliente y el documento del frontend dicen que las 25 vistas originales están aprobadas el 13 de noviembre. Las siete de ancho amplio, los tres estados de espera y las vistas 26 a 28 se aprobaron el 20 de noviembre.
- Copia del proyecto: «Frontend — vistas y diseño» (14 de noviembre) no trae la sección «Vistas de la arquitectura modular». Esta versión sí la trae, tomada del documento vivo.
- Anexo A: la copia «Anexo A — Vistas del cliente» se eliminó del proyecto en una sesión anterior, sin haberse cotejado línea a línea con este documento. Su pestaña sigue viva en el documento de arquitectura (cuerpo 5babcbef-203e). Si falta algo, se consulta la pestaña.
- ASR: el POC usa faster-whisper; el documento de arquitectura propone whisper.cpp para el cliente. Decide D-01.
- Vista de reproductor: el documento de arquitectura y la guía coinciden en que la vista de traducción a la vista usa StimulusDisplayed, pero el nombre de la tabla de eventos del dispositivo aún no está en el catálogo del servidor.
- Formatos de maqueta: las fuentes citan los anchos 390 px y 1440 px; el ancho medio y sus puntos de corte no están definidos. La guía del cliente da 600 px y 1024 px como puntos de corte (compacto, medio y amplio). Esas cifras no aparecen en el documento vivo y quedan sin confirmar hasta que Alejandro decida.
- Número de documentos: el Anexo D (D-23) fija un documento de arquitectura y un documento del frontend, con dos guías rápidas. El encargo del 20 de noviembre pide, además, un tracker por lado. Pendiente de confirmar.

## 15. Decisiones que tocan al cliente

- D-01: dónde corre el ASR. Afecta a `local_analysis`, al tamaño del modelo que se descarga y a F2-07.
- D-02: respaldo del audio del usuario. No en el MVP; más adelante, opcional y cifrado de extremo a extremo.
- D-03: segundo proveedor de voz y acentos regionales. Se elige con la prueba de audición de F3-03.
- D-04: proveedor de identidad. Un servicio OIDC administrado, antes de abrir a un segundo usuario (F6-03).
- D-05: hosting de producción. Por decidir.
- D-06: resuelta el 15 de noviembre: módulos con permisos por tiempo.
- D-07: librería de gráficos. fl_chart, tras la prueba de F4-02.
- D-11: nombre del producto. Se decide antes de publicar en tiendas.
- D-20: cobro y tiendas. La venta empieza en web y escritorio; en iOS y Android la venta de bienes digitales pasa por la tienda.

## 16. Distribución por plataforma

| Plataforma | Canal |
| --- | --- |
| Web | Hosting estático con CDN |
| iOS y iPadOS | TestFlight y luego App Store |
| Android | Prueba interna y luego Google Play |
| macOS | App notarizada, descarga directa o Mac App Store |
| Windows | Paquete MSIX firmado |
| Linux | AppImage o Flatpak, prioridad baja |

## 17. Trampas conocidas

- `packs` es el módulo de paquetes de referencia del cliente; los módulos vendibles van en `catalog`.
- En la traducción a la vista, T0 es el instante en que se muestra el texto, no el fin del audio. La latencia que se informa es el tiempo de preparación.
- Crear una sesión exige conexión, porque ahí se comprueba el permiso. El catálogo y los permisos se guardan en caché con su vencimiento.
- La compra ocurre fuera de la aplicación en la primera versión. La aplicación solo refleja el permiso al sincronizar.
- Las cifras de las maquetas son ilustrativas. No se toman como datos.
- El paquete de referencia no es lo que se compra. Usar siempre «módulo» para lo vendible.
- El índice de preparación no se dibuja como probabilidad. Sin calibración publicada dice «sin calibrar».
- El cliente web no ofrece la misma precisión de medición que el nativo; cada turno lo registra.
- Decisiones abiertas que tocan al cliente: D-01, D-07, D-11 y D-20 (sección 15).
- Maquetas que faltan desde antes: calentamiento, informe de paquete, informe de calibración, subpantallas del laboratorio, ancho medio y tema claro (sección 13).

## 18. Procedencia

- Vistas 1 a 25, decisiones de diseño, estados de espera, anchos, vistas del simulacro y vistas de la arquitectura modular: documento vivo del frontend, revisión 17.
- Arquitectura del cliente, módulos, reparto, contrato, cifrado, distribución y reportes: pestaña principal del documento de arquitectura, revisión 173; y la guía del cliente del 16 de noviembre.
- Reglas AD-04, AD-05, AD-06, AD-10 y AD-15: Anexo D.
- Anclas, invariantes, trampas y orden de la guía del cliente: se cotejaron con este documento el 20 de noviembre y se migraron lo que faltaba.
- Cambios de la segunda pasada (20 de noviembre): se corrigió la invariante 1 (los veredictos bajan del servidor; no suben); se añadieron los cuerpos de los Anexos A, B y D y el cómo llegar a un ancla; se añadieron los eventos del tope gratuito (SessionLimited, KnobLocked y JudgingDeferred); se añadió el conflicto de los puntos de corte de ancho.
- Cambios de la primera pasada (20 de noviembre): se retiraron las láminas con nombres inventados, los puntos de corte de ancho que no constan en las fuentes, la mención a una suscripción sin respaldo y la lista de temas del mapa de debilidades. Se corrigieron las referencias cruzadas y las fases de las vistas del simulacro. Lo que se mantiene de la versión anterior sale de las fuentes citadas.
