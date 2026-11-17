# Entrenador de interpretación — Frontend: vistas y diseño

Estado al 14 de noviembre de 2026. Copia del documento de Claude Docs https://claude.ai/artifact/VeovvYek97Ecs7ZzvM2V4a, que es la fuente de verdad del frontend.

El cliente Flutter tiene 25 vistas maquetadas y aprobadas el 13 de noviembre de 2026, en formato teléfono. El 14 de noviembre se añadieron tres estados de espera del reproductor y siete vistas en ancho amplio, pendientes de aprobación; las maquetas están en el lienzo Maquetas de pantallas (https://claude.ai/artifact/ScnMR8v3SgGib17MyxQWGz). Este documento reúne las decisiones de diseño, el catálogo de vistas y el orden de trabajo del frontend, y complementa el documento de arquitectura y tracker (https://claude.ai/artifact/6BA3PkksydBNdTCiXXCTiL). Las vistas del módulo `exam` (26 a 28) están en la última sección.

## Decisiones de diseño

La aplicación se diseña como un instrumento de medición, no como una aplicación de idiomas: sobria, densa en datos y con el tema oscuro como principal.

| Elemento | Decisión |
| --- | --- |
| Fondo y superficies | Grafito #0D1012; superficies #161A1E; líneas #2A3138 |
| Dirección EN→ES | Turquesa #5AD4C4, que es también el acento de la aplicación |
| Dirección ES→EN | Azul #7DB7FF |
| Veredictos | Ámbar #E9C46A parcial; naranja #FF9A57 error mayor u omisión; rojo #FF6F61 error crítico o distorsión |
| Tipografía | Space Grotesk en títulos, Inter en texto, JetBrains Mono en toda cifra |
| Formato maquetado | Teléfono, 390 × 844; ancho amplio, 1440 px, en siete vistas; el ancho medio queda pendiente, salvo en las vistas del simulacro |

- Ningún estado depende solo del color: cada veredicto lleva además una forma o un subrayado propio.
- Los colores semánticos se reservan para veredictos del juez y decisiones del motor; no se usan como decoración.
- Durante una sesión desaparece la navegación y la ventana se muestra como un anillo sin cifras.

### La métrica protagonista

La métrica principal es la ventana que el usuario sostiene (el factor f por dirección), no la calidad Q. Con un motor adaptativo, Q se mantiene más o menos constante por diseño, porque el motor aprieta cuando el usuario rinde bien; un gráfico de Q en el tiempo sale plano. El progreso real se ve en la dificultad sostenida: una ventana que se encoge hacia el tiempo real del usuario (el piso, 1.1 × ρ). Q se reserva para el paquete de referencia, que es el único instrumento honesto de comparación.

### Lo auditable

El requisito de que el usuario pueda volver a ver en qué falló y por qué se resuelve con cuatro vistas encadenadas: sala de revisión, panel del porqué, apelación y expediente. El expediente tiene vista propia y acceso desde la pantalla inicial.

## Catálogo de vistas

Son 25 vistas: 19 vienen de la tabla de pantallas del documento de arquitectura y 6 son nuevas. La navegación mantiene los cuatro destinos (Practicar, Revisar, Progreso, Cuaderno) más Perfil. La columna Archivo es el nombre de la lámina en el lienzo.

| N.º | Vista | Archivo | Destino | Qué muestra | Fase | Origen |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Hoy | Main | Practicar | Ventana sostenida por dirección con tendencia y distancia al tiempo real, sesión recomendada, pendiente de revisar, eje más débil, acceso al expediente | F2 | Arquitectura, ampliada |
| 2 | Selector de sesión | Selector | Practicar | Tipo, direcciones, agresividad, ejes activos | F2 | Arquitectura |
| 3 | Calibración del dispositivo | CalDispositivo | Practicar | Bucle de retorno, latencia, dispersión, piso de ruido, veredicto | F2 | Arquitectura |
| 4 | Calibración del usuario | CalUsuario | Practicar | Progreso por dirección, ρ, piso, inicio y techo de f | F2 | Arquitectura |
| 5 | Reproductor de sesión | Sesion | Practicar | Estado, anillo de la ventana sin cifras, nivel del micrófono, adelantar | F2 | Arquitectura |
| 6 | Tarjeta del turno | TarjetaTurno | Practicar | Arranque, margen, Q, notas por eje, unidades, decisión del motor y su valoración | F2 | Arquitectura |
| 7 | Consola de perillas | Perillas | Practicar | Un deslizador vertical por eje, nivel actual, destino, candado, frase del supervisor | F3 | Arquitectura |
| 8 | Biblioteca de paquetes | Paquetes | Practicar | Paquetes, intentos con su Q, comparar, nuevo intento | F4 | Arquitectura |
| 9 | Resumen de sesión | Resumen | Revisar | Trayectoria de f con sondeos, informe, turnos a revisar | F2 | Arquitectura |
| 10 | Sala de revisión | Sala | Revisar | Ondas alineadas con T0, fin y W, rendición coloreada por estado, unidades del original, repetir VAD | F2 | Arquitectura |
| 11 | Panel del porqué | Porque | Revisar | Nota del eje, evidencia original contra rendición, justificación, reglas activadas, versiones con que se evaluó | F2 | Arquitectura |
| 12 | Apelación | Apelacion | Revisar | Causa, comentario, estado del segundo juicio, evaluación vigente | F2 | Arquitectura |
| 13 | Historial | Historial | Revisar | Búsqueda en rendiciones, filtros, lista de sesiones | F4 | Arquitectura |
| 14 | Expediente | Expediente | Revisar | Estado de la cadena de huellas, lo guardado, evaluaciones de un turno comparadas con la vigente señalada, reevaluar, verificar, exportar | F2 | Nueva |
| 15 | Tablero de progreso | Progreso | Progreso | Ventana sostenida en el tiempo contra el tiempo real, arranque, mensaje que llega, Q, paquete | F4 | Arquitectura |
| 16 | Mapa de debilidades | Debilidades | Progreso | Mapa de calor de ejes de la rúbrica por tema, datos duros por tipo | F4 | Arquitectura |
| 17 | Comparación contra sí mismo | Comparacion | Progreso | Intentos de un paquete métrica por métrica, A/B de audio, unidad por unidad | F4 | Arquitectura |
| 18 | Informe periódico | InformePeriodico | Progreso | Calendario de práctica, lo que avanzó, errores que se repiten, plan sugerido | F4 | Nueva; antes solo figuraba como reporte |
| 19 | Cuaderno de errores | Cuaderno | Cuaderno | Tarjetas que vencen hoy, repaso, tarjetas por error, cifra, unidad o término | F4 | Arquitectura |
| 20 | Ajustes y privacidad | Ajustes | Perfil | Qué viaja y qué no, retención, consentimientos, dispositivos, calibración, plan y uso, borrado | F2 | Arquitectura |
| 21 | Laboratorio | Laboratorio | Perfil (administrador) | Pruebas del juez candidato, apelaciones por resolver, costo por sesión, golden set | F1 | Arquitectura |
| 22 | Primera ejecución | Bienvenida | Fuera de la navegación | Qué es, pasos de preparación, inicio de sesión | F2 | Nueva |
| 23 | Estados del sistema | Estados | Sobre cualquier pantalla | Sin conexión, envío del expediente, tope del día, actualización obligatoria, dispositivos | F2 | Nueva |
| 24 | Reproductor · tiempo real | TiempoReal | Practicar | Las dos partes del diálogo, anillo en estado de escucha | F5 | Nueva; variante del reproductor |
| 25 | Reproductor · cabina | Cabina | Practicar | Ondas del orador y del usuario, desfase con su zona cómoda | F6 | Nueva; variante del reproductor |

Las cifras que aparecen en las maquetas son ilustrativas, y los temas del mapa de debilidades (General, Formal, Negocios, Cifras) son provisionales.

## Vistas clave

Cuatro grupos de vistas definen el producto; el resto deriva de ellas.

### Hoy

- Figura central: la ventana sostenida por dirección (EN→ES y ES→EN lado a lado), con su tendencia y la distancia que falta hasta el tiempo real.
- Sesión recomendada con un solo botón para empezar.
- Pendiente de revisar: turnos con error crítico sin abrir, apelaciones en curso y tarjetas de repaso que vencen hoy.
- Eje más débil de la semana, con acceso directo a su evidencia.
- Estado del expediente (íntegro, turnos guardados) con acceso a su vista.
- No muestra la racha: mide constancia, no competencia.

### Reproductores de sesión

Los tres comparten controles y disposición. El de consecutiva muestra el anillo de la ventana sin cifras, el estado y el nivel del micrófono. El de tiempo real añade las dos partes del diálogo y pone el anillo en estado de escucha. El de cabina sustituye el anillo por las ondas del orador y del usuario con el desfase y su zona cómoda.

### La cadena de auditoría

Las maquetas cuentan una sola historia con el mismo turno, para probar que el recorrido cierra:

1. Sala de revisión: las ondas alineadas y la rendición coloreada muestran una cifra marcada como distorsionada.
2. Panel del porqué: la nota del eje, la evidencia (original contra lo dicho), las reglas que activó el motor y las versiones con que se evaluó.
3. Apelación: el usuario alega error de transcripción; un segundo juicio le da la razón.
4. Expediente: las dos evaluaciones quedan guardadas, con la vigente señalada y el eje que cambió.

### Progreso

El gráfico principal es la ventana sostenida en el tiempo contra la línea del tiempo real. Debajo van cuatro indicadores pequeños: arranque, porcentaje del mensaje que llega, Q (marcada como estable por diseño) y el último paquete de referencia. El mapa de debilidades cruza ejes de la rúbrica con temas, y la comparación contra sí mismo superpone los intentos de un paquete con A/B de audio.

## Cambios respecto del documento de arquitectura

La tabla de pantallas del documento de arquitectura no se modificó; estas son las diferencias que este documento introduce.

- Hoy deja de mostrar la racha y la última sesión; su contenido es el descrito arriba.
- El expediente pasa a tener vista propia. El backend ya lo soporta (reevaluación, evaluación vigente, verificación de la cadena y exportación); faltaba la pantalla.
- El informe periódico pasa de reporte a vista.
- Primera ejecución y estados del sistema (sin conexión, sincronización, tope del día, actualización obligatoria) entran al inventario.
- Los reproductores de tiempo real y de cabina se diseñan desde ahora, aunque se construyan en F5 y F6.
- En progreso, la ventana sostenida sustituye a Q como gráfico principal.

El documento de arquitectura remite a estas vistas desde su sección «Interfaz de usuario» y lleva el catálogo en su pestaña «Anexo A · Vistas del cliente».

## Estados de espera

Las cuatro esperas de una sesión se diseñan como una sola familia de animaciones sobre el anillo del reproductor; requisito registrado el 13 de noviembre de 2026, maquetado el 14 de noviembre: Preparando, Reproduciendo y Procesando tienen lámina propia y Grabando es el reproductor de sesión.

| Estado | Archivo | Cuándo ocurre | Indicador |
| --- | --- | --- | --- |
| Preparando | EstPreparando | El servidor arranca, la sesión se crea y el audio se descarga | Anillo de trazo segmentado que gira despacio, con los pasos reales debajo (conectando, descargando audio, verificando calibración) que se marcan al cumplirse |
| Reproduciendo | EstReproduciendo | Suena el orador | Anillo en el color de la dirección que late; ondas de la voz del orador; texto «Escucha» |
| Grabando | Sesion | Ventana abierta, el usuario interpreta | Anillo que se consume sin cifras y barras del micrófono que responden a la voz; es el estado con menos movimiento, para no distraer |
| Procesando | EstProcesando | VAD, transcripción, juez y motor | Anillo indeterminado con las etapas reales que se van marcando (detectando voz, transcribiendo, evaluando, decidiendo) y dónde corre cada una |

- En entrenamiento, Procesando ocupa la pantalla entre el turno y su tarjeta. En sesión continua corre en segundo plano mientras suena el segmento siguiente y solo aparece al final, como contador de turnos por evaluar.
- Las animaciones respetan la preferencia de reducir movimiento del sistema: en ese caso el anillo cambia de estado sin moverse.
- El rojo no se usa para grabar: queda reservado para errores críticos.

## Anchos de pantalla

Las 25 vistas están maquetadas en ancho de teléfono y siete de ellas también en ancho amplio (1440 px); el ancho medio está sin diseñar, salvo en las vistas del simulacro.

| Ancho | Rango propuesto | Navegación |
| --- | --- | --- |
| Compacto | Menos de 600 px | Barra inferior (maquetado) |
| Medio | 600 a 1024 px | Riel lateral angosto (maquetado solo en las vistas del simulacro) |
| Amplio | Más de 1024 px | Riel lateral con etiquetas (maquetado en siete vistas y en las del simulacro) |

La mayoría de las vistas solo se reacomoda en columnas. Siete cambian de estructura y tienen maqueta propia en ancho amplio: Hoy (tablero a dos columnas), sala de revisión con el panel del porqué fijo a la derecha, consola de perillas con las dos direcciones a la vez, tablero de progreso, historial (lista y detalle), expediente y laboratorio. El reproductor no cambia: queda centrado.

| Vista en ancho amplio | Archivo | Qué cambia frente al teléfono |
| --- | --- | --- |
| Hoy | WHoy | Dos columnas: la ventana sostenida con su gráfico a la izquierda; sesión recomendada, pendientes y semana a la derecha |
| Sala de revisión | WSala | El panel del porqué queda fijo a la derecha; arriba, los 16 turnos de la sesión con los que tienen error marcados |
| Consola de perillas | WPerillas | Las dos direcciones a la vez, como mesa de mezclas, y debajo los movimientos del supervisor |
| Tablero de progreso | WProgreso | Gráfico principal a todo el ancho, cuatro indicadores, notas por eje contra el período anterior y unidades por semana |
| Historial | WHistorial | Lista de sesiones a la izquierda y detalle a la derecha, con la tabla de turnos |
| Expediente | WExpediente | Los eventos del turno en orden, con origen, alcance y huella; a la derecha, las evaluaciones y el manifiesto |
| Laboratorio | WLaboratorio | Pruebas del juez, apelaciones y costo en tres columnas; debajo, la simulación contrafactual turno por turno |

El ancho amplio no es secundario: el criterio de salida de F2 exige Windows además de un móvil, y el núcleo de audio se construye primero en Windows (F2-02).

## Orden de trabajo y pendientes

El frontend avanza en paralelo al backend: las pantallas se construyen contra un AudioEngine falso y el contrato OpenAPI, sin depender de que el servidor esté terminado.

1. Tokens y componentes comunes del módulo design_system a partir de las maquetas (F2-01).
2. Esqueleto del cliente: navegación adaptable, rutas y cliente de API generado (F2-01).
3. Pantallas de F2: Hoy, selector, calibraciones, reproductor, tarjeta del turno, resumen, sala de revisión, panel del porqué, apelación, expediente, ajustes, primera ejecución y estados del sistema.
4. Consola de perillas (F3); el candado ya existe en el backend.
5. Progreso, mapa de debilidades, comparación, cuaderno, paquetes, historial e informe periódico (F4); las proyecciones de progreso, el cuaderno y los paquetes ya están hechos en el backend.

### Pendiente

- Aprobar los tres estados de espera y las siete vistas de ancho amplio; diseñar el ancho medio (tableta).
- Maquetas que faltan: calentamiento, informe de paquete, informe de calibración, subpantallas del laboratorio (golden set, simulación contrafactual) y suscripciones.
- Nombre del producto (D-11): la primera ejecución lleva un marcador.
- Librería de gráficos (D-07): fl_chart para los gráficos y CustomPainter para las ondas, a confirmar con una prueba.
- Actualizar la fila de Hoy en la tabla de pantallas del documento de arquitectura.
- Tema claro: el módulo app_shell lo prevé y las maquetas solo cubren el oscuro.

## Vistas del simulacro y del índice

El módulo `exam` suma tres vistas (26, 27 y 28) y un retoque de Hoy, maquetados el 14 de noviembre de 2026 en tres anchos y pendientes de aprobación. Están en un lienzo aparte, Maquetas del simulacro y del índice (https://claude.ai/artifact/KFrLFSt7Tt86UfAvkCdkgw); el plan del módulo está en el Anexo B del documento de arquitectura.

| Vista | Destino | Qué muestra | Teléfono, 390 px | Ancho medio, 834 px | Ancho amplio, 1440 px |
| --- | --- | --- | --- | --- | --- |
| 26 · Resultado del simulacro | Revisar | Nota por dirección contra el umbral, unidades de información, datos duros y errores críticos aparte, ítems a revisar, validez del intento | Main | MResultado | WResultado |
| 27 · Índice de preparación | Progreso | Estado, rango por dirección frente al umbral, intentos que lo sostienen, cobertura y calibración externa | Indice | MIndice | WIndice |
| 28 · Calificación externa | Perfil (administrador) | Cola a ciegas, turno con original y rendición, estado por unidad, juicio global, acuerdo con el juez | LabCalificacion | MLabCalificacion | WLabCalificacion |
| 1 · Hoy con el índice (retoque) | Practicar | La vista Hoy con el índice debajo de la ventana sostenida | HoyIndice | MHoyIndice | WHoyIndice |

- Es el primer ancho medio maquetado: riel lateral angosto y contenido a dos columnas. Las 25 vistas anteriores siguen sin él.
- En el ancho amplio, la calificación externa deja la cola fija a la izquierda, el turno al centro y el acuerdo a la derecha.
- La métrica protagonista no cambia: Hoy y Progreso conservan la ventana sostenida. Solo dentro de las vistas del simulacro manda la nota, porque allí la ventana no se mueve.
- El índice se dibuja como un rango con su centro frente al umbral, y dice que no es una probabilidad de aprobar.
- Los estados usan la familia existente: ámbar para sin calibrar, naranja y rojo solo para errores, y cada estado lleva además texto o forma.
- Pendiente: aprobar estas láminas, incorporarlas al lienzo original y maquetar los retoques del selector de sesión, la biblioteca de paquetes y ajustes.
