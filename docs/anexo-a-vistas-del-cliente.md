# Anexo A · Vistas del cliente

Copia del anexo del documento de arquitectura y tracker (pestaña «Anexo A · Vistas del cliente»: https://claude.ai/artifact/6BA3PkksydBNdTCiXXCTiL#e7f2ee27-dfa4). La sección «Interfaz de usuario» del documento principal remite a este anexo.

Las 25 vistas del cliente quedaron maquetadas y aprobadas el 13 de noviembre de 2026, en formato teléfono (390 × 844). Las maquetas están en el lienzo Maquetas de pantallas (https://claude.ai/artifact/ScnMR8v3SgGib17MyxQWGz), agrupadas por destino; las cifras que muestran son ilustrativas. El 14 de noviembre se sumaron las vistas 26 a 28 y un retoque de Hoy, en tres anchos y pendientes de aprobación, en el lienzo Maquetas del simulacro y del índice (https://claude.ai/artifact/KFrLFSt7Tt86UfAvkCdkgw).

## Lenguaje visual

- Instrumento de medición, no aplicación de idiomas: tema oscuro como principal, fondo grafito (#0D1012) y superficies #161A1E.
- Un color por dirección: turquesa (#5AD4C4) para EN→ES, que es también el acento, y azul (#7DB7FF) para ES→EN.
- Colores semánticos solo para veredictos: ámbar (#E9C46A) parcial, naranja (#FF9A57) error mayor u omisión, rojo (#FF6F61) error crítico o distorsión. Ningún estado depende solo del color: cada uno lleva además forma o subrayado propio.
- Tipografía: Space Grotesk en títulos, Inter en texto y JetBrains Mono en toda cifra.
- La ventana que el usuario sostiene (factor f por dirección) es la métrica protagonista; la calidad Q se muestra como secundaria, porque el motor la mantiene estable por diseño.

## Catálogo de vistas

| N.º | Vista | Archivo en el lienzo | Destino | Qué muestra | Fase | Origen |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Hoy | Main | Practicar | Ventana sostenida por dirección con tendencia y distancia al tiempo real, sesión recomendada, pendiente de revisar, eje más débil, acceso al expediente | F2 | Tabla de pantallas, ampliada |
| 2 | Selector de sesión | Selector | Practicar | Tipo, direcciones, agresividad, ejes activos | F2 | Tabla de pantallas |
| 3 | Calibración del dispositivo | CalDispositivo | Practicar | Bucle de retorno, latencia, dispersión, piso de ruido, veredicto | F2 | Tabla de pantallas |
| 4 | Calibración del usuario | CalUsuario | Practicar | Progreso por dirección, ρ, piso, inicio y techo de f | F2 | Tabla de pantallas |
| 5 | Reproductor de sesión | Sesion | Practicar | Estado, anillo de la ventana sin cifras, nivel del micrófono, adelantar | F2 | Tabla de pantallas |
| 6 | Tarjeta del turno | TarjetaTurno | Practicar | Arranque, margen, Q, notas por eje, unidades, decisión del motor y su valoración | F2 | Tabla de pantallas |
| 7 | Consola de perillas | Perillas | Practicar | Un deslizador vertical por eje, nivel actual, destino, candado, frase del supervisor | F3 | Tabla de pantallas |
| 8 | Biblioteca de paquetes | Paquetes | Practicar | Paquetes, intentos con su Q, comparar, nuevo intento | F4 | Tabla de pantallas |
| 9 | Resumen de sesión | Resumen | Revisar | Trayectoria de f con sondeos, informe, turnos a revisar | F2 | Tabla de pantallas |
| 10 | Sala de revisión | Sala | Revisar | Ondas alineadas con T0, fin y W, rendición coloreada por estado, unidades del original, repetir VAD | F2 | Tabla de pantallas |
| 11 | Panel del porqué | Porque | Revisar | Nota del eje, evidencia original contra rendición, justificación, reglas activadas, versiones con que se evaluó | F2 | Tabla de pantallas |
| 12 | Apelación | Apelacion | Revisar | Causa, comentario, estado del segundo juicio, evaluación vigente | F2 | Tabla de pantallas |
| 13 | Historial | Historial | Revisar | Búsqueda en rendiciones, filtros, lista de sesiones | F4 | Tabla de pantallas |
| 14 | Expediente | Expediente | Revisar | Estado de la cadena de huellas, lo guardado, evaluaciones de un turno comparadas con la vigente señalada, reevaluar, verificar, exportar | F2 | Nueva |
| 15 | Tablero de progreso | Progreso | Progreso | Ventana sostenida en el tiempo contra el tiempo real, arranque, mensaje que llega, Q, paquete | F4 | Tabla de pantallas |
| 16 | Mapa de debilidades | Debilidades | Progreso | Mapa de calor de ejes de la rúbrica por tema, datos duros por tipo | F4 | Tabla de pantallas |
| 17 | Comparación contra sí mismo | Comparacion | Progreso | Intentos de un paquete métrica por métrica, A/B de audio, unidad por unidad | F4 | Tabla de pantallas |
| 18 | Informe periódico | InformePeriodico | Progreso | Calendario de práctica, lo que avanzó, errores que se repiten, plan sugerido | F4 | Nueva; antes solo figuraba como reporte |
| 19 | Cuaderno de errores | Cuaderno | Cuaderno | Tarjetas que vencen hoy, repaso, tarjetas por error, cifra, unidad o término | F4 | Tabla de pantallas |
| 20 | Ajustes y privacidad | Ajustes | Perfil | Qué viaja y qué no, retención, consentimientos, dispositivos, calibración, plan y uso, borrado | F2 | Tabla de pantallas |
| 21 | Laboratorio | Laboratorio | Perfil (administrador) | Pruebas del juez candidato, apelaciones por resolver, costo por sesión, golden set | F1 | Tabla de pantallas |
| 22 | Primera ejecución | Bienvenida | Fuera de la navegación | Qué es, pasos de preparación, inicio de sesión | F2 | Nueva |
| 23 | Estados del sistema | Estados | Sobre cualquier pantalla | Sin conexión, envío del expediente, tope del día, actualización obligatoria, dispositivos | F2 | Nueva |
| 24 | Reproductor · tiempo real | TiempoReal | Practicar | Las dos partes del diálogo, anillo en estado de escucha | F5 | Nueva; variante del reproductor |
| 25 | Reproductor · cabina | Cabina | Practicar | Ondas del orador y del usuario, desfase con su zona cómoda | F6 | Nueva; variante del reproductor |
| 26 | Resultado del simulacro | Main, MResultado y WResultado, en el lienzo del simulacro | Revisar | Nota por dirección contra el umbral, unidades de información, datos duros y errores críticos aparte, tiempo fuera de la nota, ítems a revisar y validez del intento | F4 | Nueva; módulo exam (Anexo B) |
| 27 | Índice de preparación | Indice, MIndice y WIndice, en el lienzo del simulacro | Progreso | Estado (insuficiente, sin calibrar o calibrado), rango por dirección frente al umbral, intentos que lo sostienen, cobertura y calibración externa | F4 | Nueva; módulo exam (Anexo B) |
| 28 | Calificación externa | LabCalificacion, MLabCalificacion y WLabCalificacion, en el lienzo del simulacro | Perfil (administrador) | Cola a ciegas, turno con original y rendición, estado por unidad, juicio global y acuerdo con el juez | F4 | Nueva; subpantalla del laboratorio |

## Cambios respecto de la tabla de pantallas

- Hoy deja de mostrar la racha. Su figura central es la ventana que el usuario sostiene por dirección, y suma lo pendiente de revisar, el eje más débil de la semana y el acceso al expediente.
- El expediente pasa a tener vista propia: lo guardado, su verificación y el historial de evaluaciones de cada turno.
- El tablero de progreso tiene la ventana sostenida como gráfico principal; la calidad Q queda como secundaria.
- Los avisos de sincronización, uso y actualización se diseñan como una sola familia.

## Vistas del simulacro y del índice

Tres vistas nuevas (26, 27 y 28) y un retoque de Hoy quedaron maquetados el 14 de noviembre de 2026 en tres anchos, pendientes de aprobación. Están en un lienzo aparte, Maquetas del simulacro y del índice (https://claude.ai/artifact/KFrLFSt7Tt86UfAvkCdkgw), porque el lienzo original no se pudo modificar desde la sesión que las hizo; conviene incorporarlas allí.

| Vista | Teléfono, 390 px | Ancho medio, 834 px | Ancho amplio, 1440 px |
| --- | --- | --- | --- |
| 26 · Resultado del simulacro | Main | MResultado | WResultado |
| 27 · Índice de preparación | Indice | MIndice | WIndice |
| 28 · Calificación externa | LabCalificacion | MLabCalificacion | WLabCalificacion |
| 1 · Hoy con el índice (retoque) | HoyIndice | MHoyIndice | WHoyIndice |

- Ancho medio: riel lateral angosto y contenido a dos columnas. Es el primer ancho medio maquetado; las 25 vistas anteriores todavía no lo tienen.
- Ancho amplio: riel con etiquetas. En la calificación externa la cola queda fija a la izquierda.
- En las vistas del simulacro la nota es la figura principal. Hoy conserva la ventana sostenida como figura central y el índice va debajo.
- El índice se dibuja como un rango con su centro frente al umbral, nunca como una probabilidad de aprobar.
- Las cifras son ilustrativas. El ejemplo usa el formato Miniescenarios, con umbral de 70 %.
- Sin maqueta todavía: los retoques del selector de sesión, la biblioteca de paquetes y ajustes.

## Pendiente

- Versiones de tableta y escritorio, en especial la sala de revisión con el panel del porqué fijo y la consola de perillas.
- Vistas sin maqueta todavía: calentamiento, informe de paquete, informe de calibración, subpantallas del laboratorio (golden set, simulación contrafactual) y suscripciones.
- Nombre del producto (D-11): la primera ejecución lleva un marcador.
- Tokens y componentes del módulo design_system a partir de estas maquetas (F2-01).
