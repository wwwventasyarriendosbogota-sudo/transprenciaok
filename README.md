# Window Transparency — macOS Sierra

Aplicación de barra de menú para intentar controlar el alpha de la ventana activa de Chrome o Firefox.

## Cómo compilar sin Xcode en tu Mac

1. Crea un repositorio nuevo en GitHub.
2. Sube TODOS los archivos de este ZIP manteniendo las carpetas.
3. En GitHub entra a **Actions**.
4. Selecciona **Build WindowTransparency for macOS Sierra**.
5. Pulsa **Run workflow**.
6. Cuando termine, abre la ejecución y descarga el artefacto:
   `WindowTransparency-macOS-Sierra`
7. Descomprime el ZIP en tu Mac Sierra.
8. Copia `WindowTransparency.app` a Aplicaciones.
9. Ve a:
   Preferencias del Sistema > Seguridad y privacidad > Privacidad > Accesibilidad
10. Agrega `WindowTransparency.app` y marca la casilla.
11. Abre Chrome o Firefox, selecciona su ventana.
12. Pulsa **α** en la barra de menú y mueve el slider.

## Importante

Esta aplicación usa `CGSSetWindowAlpha`, una API privada de macOS. Está pensada para uso local en Sierra y no para la Mac App Store.

La compilación se realiza en un runner moderno de GitHub con:
`-mmacosx-version-min=10.12`

Esto intenta producir un binario compatible con Sierra, pero la compatibilidad real depende de las APIs disponibles y de la versión concreta de Chrome/Firefox.

Si el control no afecta a la ventana, revisa primero Accesibilidad y prueba con una ventana normal de Chrome/Firefox.
