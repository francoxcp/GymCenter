# 📱 Instrucciones para Agregar el Logo de la App

## ¿Qué es el Logo de la App?

El logo de la app es el **icono que aparece en la pantalla de inicio** de tu dispositivo después de instalar la aplicación. También es el icono que aparece en la tienda de aplicaciones (Google Play Store / Apple App Store).

## Requisitos del Logo

### Especificaciones Técnicas:
- **Formato:** PNG con fondo transparente (recomendado) o con fondo sólido
- **Tamaño:** 1024x1024 px (mínimo recomendado)
- **Forma:** Cuadrado
- **Peso:** Menor a 1 MB
- **Colores:** RGB (no CMYK)

### Recomendaciones de Diseño:
✅ Diseño simple y reconocible
✅ Colores que contrasten bien
✅ Evita texto muy pequeño (se verá borroso)
✅ Prueba cómo se ve en círculo (Android adaptive icons)
✅ Prueba cómo se ve en cuadrado con bordes redondeados (iOS)

## 🚀 Pasos para Agregar tu Logo

### Paso 1: Preparar el Archivo
1. Guarda tu logo como `app_icon.png`
2. Asegúrate de que tenga al menos 1024x1024 píxeles
3. Si tiene fondo transparente, mejor aún

### Paso 2: Colocar el Archivo
Coloca el archivo `app_icon.png` en la carpeta:
```
ChamosFitnessCenter/
  └── assets/
      └── icons/
          └── app_icon.png  ← AQUÍ
```

### Paso 3: Generar los Iconos
Abre una terminal en la carpeta del proyecto y ejecuta:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

Esto generará automáticamente todas las versiones del icono para Android e iOS.

### Paso 4: Verificar
Después de generar los iconos, verás nuevos archivos en:

**Android:**
```
android/app/src/main/res/mipmap-hdpi/
android/app/src/main/res/mipmap-mdpi/
android/app/src/main/res/mipmap-xhdpi/
android/app/src/main/res/mipmap-xxhdpi/
android/app/src/main/res/mipmap-xxxhdpi/
```

**iOS:**
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

### Paso 5: Probar
Desinstala la app de tu dispositivo (si ya está instalada) y vuelve a instalarla:

```bash
flutter run -d RFCR50WT3HT
```

El nuevo icono debería aparecer en tu dispositivo.

## 🎨 Configuración Actual

El archivo `pubspec.yaml` está configurado con:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#000000"  # Negro
  adaptive_icon_foreground: "assets/icons/app_icon.png"
  remove_alpha_ios: true
```

### Personalizar el Fondo (Android Adaptive Icon)
Si quieres cambiar el color de fondo del icono adaptativo de Android, edita la línea:
```yaml
adaptive_icon_background: "#000000"  # Cambia este color hexadecimal
```

Por ejemplo:
- `"#FFEB00"` para amarillo (tu color primario)
- `"#FFFFFF"` para blanco
- `"#1A1A1A"` para gris oscuro

## ❓ Problemas Comunes

### El icono no cambia después de ejecutar los comandos
- Desinstala completamente la app del dispositivo
- Limpia el proyecto: `flutter clean`
- Vuelve a instalar: `flutter run`

### El icono se ve pixelado
- Usa una imagen más grande (mínimo 1024x1024)
- Asegúrate de que sea PNG de alta calidad

### El icono tiene bordes blancos no deseados
- Verifica que el PNG tenga fondo transparente
- O ajusta el `adaptive_icon_background` a un color que combine

## 📝 Notas Adicionales

**Para Producción (Google Play / App Store):**
- Necesitarás una versión de 512x512 para Google Play
- Necesitarás una versión de 1024x1024 para App Store
- Guarda versiones de alta resolución de tu logo

**Herramientas Útiles:**
- [AppIcon.co](https://www.appicon.co/) - Generador de iconos online
- [MakeAppIcon](https://makeappicon.com/) - Otra opción popular
- Figma / Adobe Illustrator - Para diseñar el logo

---

**¿Necesitas ayuda con el diseño del logo?**
Si aún no tienes un logo diseñado, puedo ayudarte a crear un placeholder temporal o sugerirte herramientas para diseñarlo.
