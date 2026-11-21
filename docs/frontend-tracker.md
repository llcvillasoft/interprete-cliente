# Frontend · tracker

Estado al 21 de noviembre de 2026. Tracker del producto para el cliente Flutter. Es la fuente del estado de F2 (cliente), de la parte de cliente de F3 y F4, y de las vistas del cliente en M2-08 y M5. Su arquitectura, sus vistas y su diseño están en «Frontend — documento maestro». El estado del backend está en «Backend — tracker».

Fuentes: tracker de la pestaña principal del documento de arquitectura (revisión 173; filas F2-01 a F2-16 en la línea 2484 del texto, y F3, F4 y M); documento vivo del frontend (revisión 17: catálogo de vistas, retoques y ancho medio); Anexo D (AD-15 y AD-12); guía rápida del cliente (16 de noviembre).

## 1. Cómo se lleva

- Estados: Pendiente, En curso, Hecho o Bloqueado (a la espera de algo externo).
- «Hecho» significa que el criterio de salida de la fila se cumple en las plataformas que nombra, que las pruebas están en verde y que las puertas de calidad pasan en CI.
- Cada entregable vive en una rama con su identificador (F2-01, M2-08…). El PR va contra `main`; lo revisa y lo mezcla Alejandro.
- Estados de las maquetas: Sin maquetar, Maquetada, Pendiente de aprobación y Aprobada (con la fecha de aprobación).
- Al cerrar un entregable se anota su commit y una línea de nota en su fila.

## 2. Último punto de retoma

- Repositorio `llcvillasoft/interprete-cliente`, creado con la documentación de vistas y diseño (commit 31068fd). La pantalla Hoy, la navegación adaptable, el cliente de API y los ratchets de calidad llegaron con el PR #3 (commit 8bd6fe2) y el PR #4 (commit a0c3972), ambos en `main`.
- Los textos visibles de la presentación pasaron a `app/lib/recursos/textos.dart` con el PR #5 (commit b0ec407), precedido de su prueba (commit 207362d).
- El documento maestro y este tracker llegaron con el PR #6 (commit 02f55b0).
- CI: en `main`, el run 44924181340 (PR #15) da en verde todos los jobs de `interfaz`: web, Android, Windows e iOS. Con eso F2-01 cumple su criterio de salida.
- F2-09 (PR #14, commit 12c574d): mecanismo de la bandeja de salida, en verde en CI.
- F2-02 (PR #16, commits f7b419e, ea73b9d y 7584496, pendiente de fusión): puente FFI en Dart en `app/lib/datos/nucleo_audio*.dart`, con las pruebas nuevas en verde en el job `app`. La biblioteca nativa se compila en CI antes de las pruebas de Flutter.
- Siguiente paso de F2: en F2-02, el backend WASAPI y la integración de CMake en Windows, con la medición en un equipo Windows; en F2-09, los eventos del expediente (F2-08) y la pantalla de estado de envío.

## 3. Fases del cliente

| Fase | Criterio de salida | Estado | Notas |
| --- | --- | --- | --- |
| F2 · Cliente MVP | Sesión adaptativa completa en el cliente, en Windows y en un móvil, con el criterio 1 del POC cumplido en ambos | En curso | Backend de F2 hecho (F2-17 a F2-23, en «Backend — tracker»); en el cliente, F2-01 hecho; F2-02 y F2-09 en curso; el resto pendiente |
| F3 · Multieje | Un segundo eje converge en simulación y en uso real sin degradar la pausa | En curso | Cliente pendiente: consola de perillas y mezcla de ruido en el dispositivo |
| F4 · Progreso | Un paquete de referencia repetido muestra el progreso métrica por métrica | Pendiente en cliente | F4-02 pendiente; vistas de progreso maquetadas |
| F5 · Tiempo real | El interlocutor vivo cumple su objetivo de latencia en uso real | Pendiente | Reproductor de tiempo real (vista 24) |
| F6 · Producto | Cabina, dominios, multiusuario y publicación en tiendas | Pendiente | Reproductor de cabina (vista 25); distribución en tiendas (D-05, D-20) |

## 4. Filas de F2 (cliente)

| ID | Entregable | Estado | Criterio de salida | Notas |
| --- | --- | --- | --- | --- |
| F2-01 | Esqueleto del cliente: navegación, diseño, cliente de API generado | Hecho | Compila en web, Windows, iOS y Android | Repositorio con la documentación de vistas y diseño (31068fd); pantalla Hoy, navegación adaptable, cliente de API y ratchets de calidad (PR #3 en 8bd6fe2 y PR #4 en a0c3972); textos externalizados (PR #5 en b0ec407); jobs de Windows, iOS y Android en el PR #7 (merge e48d094). Todos los jobs de `interfaz` están en verde en `main` (run 44924181340, PR #15). La prueba de integración de iOS se atasca a veces esperando el servicio de Dart; el PR #15 añade un reintento único del paso que reinicia el simulador, y la causa de fondo sigue abierta |
| F2-02 | Núcleo de audio dúplex con miniaudio, primero en Windows | En curso | Criterio 1 del POC en Windows | Rebanadas 1 y 2 en `main` con el PR #8 (merge 0938298): núcleo en C sobre miniaudio v0.11.26 (7e80a0d) y marca T0 con precisión de muestra en bloques programados (a0e315a); 205 comprobaciones en verde con backend nulo y ThreadSanitizer sin avisos; CI en verde en 5c1d848. Puente FFI en Dart en el PR #16 (ea73b9d; CI en 7584496), pendiente de fusión: 14 pruebas nuevas en verde en el job `app`, con la biblioteca compilada en CI. Falta: backend WASAPI, integración de CMake en Windows y medición en Windows |
| F2-03 | Núcleo de audio en iOS y Android | Pendiente | Criterio 1 del POC en un iPhone y un Android | — |
| F2-04 | Núcleo de audio web | Pendiente | Precisión documentada y marcada como web | — |
| F2-05 | Calibración del dispositivo | Pendiente | Veredicto apto o no apto por ruta de audio | Ver regla de calibración en el backend (F2-19) |
| F2-06 | VAD local y prueba de equivalencia con el POC | Pendiente | Tramos dentro de la tolerancia sobre el audio dorado | Silero en ONNX Runtime, como en el POC |
| F2-07 | ASR local según D-01 | Pendiente | Sensibilidad del juez dentro del umbral | Decisión D-01 abierta |
| F2-08 | Expediente local cifrado con cadena de huellas | Pendiente | Verificación local en verde | — |
| F2-09 | Bandeja de salida y sincronización | En curso | Una sesión sin conexión se sincroniza completa | Mecanismo listo (PR #14, commit 12c574d) en `app/lib/dominio/bandeja_salida.dart`: orden, lotes de hasta 1000, reintentos con espera exponencial, rechazos definitivos aparte y sincronización única en curso. `ClienteHttp.enviarEventos` llama a `POST /v1/events:batch`. Probado con transporte simulado y con `MockClient`. Falta: generar los eventos del expediente (F2-08) y la pantalla de estado de envío |
| F2-10 | Calibración del usuario (ρ) | Pendiente | ρ y límites de f por dirección | El backend ya fija ρ y límites con UserCalibrated (F2-19) |
| F2-11 | Entrenamiento: reproductor y tarjeta del turno | Pendiente | Sesión de revisión por turno completa | Vistas 5 y 6 aprobadas en maqueta |
| F2-12 | Sesión continua con informe | Pendiente | Hito D del POC reproducido en el cliente | El informe de sesión ya lo genera el backend (F2-17) |
| F2-13 | Sala de revisión y panel del porqué | Pendiente | Todo error lleva a su evidencia y a su audio | Vistas 10 y 11 aprobadas en maqueta |
| F2-14 | Apelaciones | Pendiente | Flujo de cinco pasos completo | El backend ya la sirve (F2-18); vista 12 aprobada en maqueta |
| F2-15 | Ajustes y privacidad en el cliente | Pendiente | Consentimiento, retención, exportación y borrado | Vista 20 aprobada, con retoque pendiente |
| F2-16 | Matriz de dispositivos y arnés de audio | Pendiente | Resultados por dispositivo guardados | Matriz propuesta: equipo Windows del POC, un Mac, un iPhone, una tableta y dos Android de gamas distintas |

## 5. Consola y parte de cliente de F3

| Elemento | Estado | Notas |
| --- | --- | --- |
| Consola de perillas (vista 7) | Maquetada y aprobada el 13 de noviembre; pantalla del cliente pendiente | Backend F3-07 hecho (commit bd133e0): candado por perilla y dirección, con KnobLocked y KnobReleased |
| Mezcla de ruido en el dispositivo (F3-04, backend) | En curso | Lógica en el backend (ab9425f); la mezcla en el dispositivo llega con el cliente de F2 |
| Aplicador de voz: velocidad y acento (F3-03) | En curso en backend | Sin tarea de cliente registrada; depende de D-03 |

## 6. Progreso y gráficos (F4)

| Elemento | Estado | Notas |
| --- | --- | --- |
| F4-02 · Tablero y gráficos (D-07) | Pendiente | Librería a confirmar con una prueba en F4: fl_chart candidato; CustomPainter para las ondas |
| Tablero de progreso (vista 15) | Aprobada el 13 de noviembre | Retoque pendiente: series por capacidad (M2-06) |
| Mapa de debilidades (vista 16) | Aprobada el 13 de noviembre | Retoque pendiente: precisión por tipo de unidad (M2-06). Los temas del mapa son provisionales |
| Comparación contra sí mismo (vista 17) | Aprobada el 13 de noviembre | — |
| Informe periódico (vista 18) | Aprobada el 13 de noviembre | Origen «Nueva; antes solo figuraba como reporte» |
| Historial (vista 13) | Aprobada el 13 de noviembre | — |
| Cuaderno de errores (vista 19) | Aprobada el 13 de noviembre | Backend F4-04 hecho |

## 7. Vistas y estado de maquetas

El catálogo de 25 vistas (1 a 25) está en el documento vivo del frontend, revisión 17. Son 19 de la tabla de pantallas del documento de arquitectura y 6 nuevas.

| Grupo | Vistas | Estado | Etapa de integración |
| --- | --- | --- | --- |
| Catálogo original, teléfono | 1 a 25 | Maquetadas y aprobadas el 13 de noviembre | — |
| Retoques a vistas existentes | 1, 2, 8, 15 y 16, 20, 23 y 25 | Pendientes de maquetar | Hoy y el selector (M2-08); biblioteca (M2-08); progreso y debilidades (M2-06); ajustes (M2-08); estados del sistema (M2-08); reproductor de cabina (M4-01) |
| Vistas del simulacro | 26 a 28 y retoque de Hoy con el índice | Maquetadas el 14 de noviembre en tres anchos, con láminas Main, M y W; aprobadas el 20 de noviembre | F4-12, F4-13 y F4-14 (backend) |
| Estados de espera (preparando, reproduciendo, grabando, procesando) | Tres estados del reproductor | Maquetados el 14 de noviembre; aprobados el 20 de noviembre | F2 |
| Anchos amplios (siete vistas) | Hoy, sala de revisión, consola, progreso, historial, expediente y laboratorio | Maquetadas el 14 de noviembre; aprobadas el 20 de noviembre | F2 a F4 |
| Ancho medio (tableta) | Solo las vistas del simulacro (26 a 28) | Maquetado el 14 de noviembre y aprobado el 20 de noviembre; las 25 vistas anteriores no lo tienen | Diseñar el resto del ancho medio |
| Catálogo de módulos y detalle | 29 y 30 | Sin maquetar | M2-08 |
| Reproductor de traducción a la vista | 31 | Sin maquetar | M2-08 |
| Constancia y horas | 32 | Sin maquetar | M5-02 |
| Panel del instructor | 33 | Sin maquetar | M5-01 |

Las vistas 24 (tiempo real) y 25 (cabina) figuran en el catálogo de 25 aprobadas el 13 de noviembre, como variantes del reproductor. La 25 tiene un retoque pendiente para la simultánea corta (M4-01).

## 8. Decisiones que tocan al cliente

| ID | Decisión | Estado | Bloquea |
| --- | --- | --- | --- |
| D-01 | Dónde corre el ASR (whisper.cpp en el dispositivo, respaldo en servidor) | Abierta | F2-07 |
| D-02 | Respaldo del audio del usuario | Abierta; no en el MVP | Exportación completa |
| D-03 | Segundo proveedor de voz y acentos | Abierta | F3-03 y la parte de voz del cliente |
| D-04 | Proveedor de identidad (OIDC administrado) | Abierta | F6-03 |
| D-05 | Hosting de producción | Abierta | F6-05 |
| D-06 | Modos, suscripciones y multiusuario | Resuelta el 15 de noviembre (módulos con permisos por tiempo) | — |
| D-07 | Librería de gráficos | Abierta; fl_chart tras la prueba de F4-02 | F4-02 |
| D-11 | Nombre del producto | Abierta | Publicar en tiendas |
| D-20 | Cobro y tiendas (la venta empieza en web y escritorio) | Abierta | M5-04 |

## 9. Conflictos entre fuentes

Los conflictos de contenido (Hoy con o sin racha, aprobación de vistas, anchos de maqueta, D-23 y el Anexo A) están en la sección 14 de «Frontend — documento maestro».

## 10. Pendientes

- F2-01 está hecho desde el run 44924181340 sobre `main`; no quedan pendientes.
- Cerrar F2-02: fusionar el PR #16 y después backend WASAPI, integración de CMake en Windows y medición del criterio 1 en Windows, que necesita un equipo Windows.
- F2-09: generar los eventos del expediente (depende de F2-08) y la pantalla de estado de envío.
- Maquetar las vistas 29 a 31 (M2-08), la 32 (M5-02) y la 33 (M5-01).
- Maquetar los retoques pendientes de la lista de la sección 7.
- Decidir D-01 antes de F2-07, D-07 antes de F4-02 y D-11 antes de publicar.
