# language: es
Característica: Pantalla Hoy
  Hoy es la primera pantalla de la aplicación. Muestra la ventana sostenida de cada dirección y la navegación, que cambia según el ancho disponible.

  @web @android @ios @windows
  Escenario: La ventana sostenida se muestra para cada dirección
    Dado una cuenta con el entrenador básico
    Cuando abre la aplicación
    Entonces ve la ventana sostenida de EN→ES
    Y ve la ventana sostenida de ES→EN

  @web @android @ios @windows
  Escenario: En ancho compacto la navegación es una barra inferior
    Dado una cuenta con el entrenador básico
    Cuando abre la aplicación con un ancho de 390 píxeles
    Entonces la navegación aparece como barra inferior

  @web @android @ios @windows
  Escenario: En ancho amplio la navegación es un riel con etiquetas
    Dado una cuenta con el entrenador básico
    Cuando abre la aplicación con un ancho de 1440 píxeles
    Entonces la navegación aparece como riel con etiquetas

  @web @android @ios @windows
  Escenario: Durante una sesión el anillo no muestra cifras
    Dado una cuenta con el entrenador básico
    Cuando abre la aplicación
    Y inicia una sesión de práctica
    Y la ventana de grabación está abierta
    Entonces el anillo no muestra cifras
