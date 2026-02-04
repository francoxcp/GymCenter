# 🔄 Transferir Proyecto a MacBook

## Opción 1: GitHub (Recomendado) ⭐

### En Windows (Preparar):

```powershell
# 1. Inicializar git si no existe
git init

# 2. Agregar todos los archivos
git add .

# 3. Commit inicial
git commit -m "feat: iOS setup complete - ready for MacBook testing"

# 4. Crear repositorio en GitHub (ir a github.com/new)
# Luego conectar:
git remote add origin https://github.com/TU_USUARIO/chamos-fitness-center.git
git branch -M main
git push -u origin main
```

### En MacBook (Descargar):

```bash
# 1. Clonar el proyecto
git clone https://github.com/TU_USUARIO/chamos-fitness-center.git
cd chamos-fitness-center

# 2. Ejecutar script de setup
chmod +x scripts/setup_ios.sh
./scripts/setup_ios.sh

# 3. Conectar iPhone y ejecutar
flutter run
```

---

## Opción 2: Carpeta Comprimida (USB/Email)

### En Windows:

```powershell
# 1. Limpiar builds para reducir tamaño
flutter clean
Remove-Item -Recurse -Force build, .dart_tool

# 2. Crear ZIP (clic derecho → Comprimir)
# O por PowerShell:
Compress-Archive -Path D:\ChamosFitnessCenter\* -DestinationPath D:\chamos-fitness.zip
```

**Transferir via:**
- USB
- Email (si < 25MB)
- Google Drive / Dropbox
- AirDrop (Mac a Mac)

### En MacBook:

```bash
# 1. Descomprimir
unzip chamos-fitness.zip -d ~/Developer/

# 2. Ir al proyecto
cd ~/Developer/chamos-fitness-center

# 3. Setup
./scripts/setup_ios.sh

# 4. Ejecutar
flutter run
```

---

## Opción 3: AirDrop (Mac ↔ Mac)

### Si estás cerca de otra Mac:

1. **En Windows:** Primero pasar a una Mac intermedia
2. **Entre Macs:** 
   - Carpeta del proyecto → Clic derecho → Compartir → AirDrop
   - Seleccionar MacBook de destino
   - En MacBook: Aceptar → Guardar en `~/Developer/`

---

## 📦 Archivos a Incluir (Checklist)

Asegurar que estos archivos/carpetas estén en la transferencia:

### ✅ Esenciales
- [ ] `lib/` - Código fuente
- [ ] `assets/` - Imágenes y recursos
- [ ] `ios/` - Configuración iOS ⭐ NUEVO
- [ ] `android/` - Configuración Android
- [ ] `pubspec.yaml` - Dependencias
- [ ] `.env` - Variables de entorno de Supabase

### ✅ Documentación
- [ ] `docs/IOS_SETUP_GUIDE.md` ⭐ NUEVO
- [ ] `docs/PRODUCCION_CHECKLIST.md`
- [ ] `README.md`

### ✅ Scripts
- [ ] `scripts/setup_ios.sh` ⭐ NUEVO
- [ ] `scripts/README.md`

### ✅ Base de Datos
- [ ] `database/*.sql` - Scripts de Supabase

### ❌ NO incluir (ocupan mucho espacio)
- [ ] `build/` - Se regenera automáticamente
- [ ] `.dart_tool/` - Se regenera automáticamente
- [ ] `ios/Pods/` - Se instala con `pod install`
- [ ] `android/.gradle/` - Se regenera automáticamente

---

## 🎯 Pasos en la MacBook (Resumen)

```bash
# 1. Verificar Flutter
flutter doctor

# 2. Ir al proyecto
cd ~/Developer/chamos-fitness-center

# 3. Setup automático
./scripts/setup_ios.sh

# 4. Conectar iPhone (USB)
# - Desbloquear iPhone
# - "Confiar en este ordenador" → Confiar
# - Activar Modo de Desarrollador

# 5. Ejecutar
flutter run

# 6. En Xcode (si hay problemas de firma):
open ios/Runner.xcworkspace
# Cambiar Team y Bundle ID en Signing & Capabilities
```

---

## ⚠️ Verificar Antes de Transferir

```powershell
# En Windows, verificar que el proyecto compila:
flutter clean
flutter pub get
flutter analyze

# Debe mostrar: "No issues found!"
```

---

## 📱 Configurar iPhone (Antes de Conectar)

En el iPhone:

1. **Ajustes → General → Información**
   - Verificar versión de iOS (mínimo iOS 12)

2. **Ajustes → Privacidad y Seguridad → Modo de Desarrollador**
   - Activar
   - Reiniciar iPhone

3. **Conectar con cable USB** (no funciona con WiFi la primera vez)

---

## 🆘 Si Algo Sale Mal

### Error: "No podfile found"
```bash
cd ios
pod install
cd ..
```

### Error: "Developer disk image not found"
- Actualizar Xcode a la última versión
- iOS del iPhone debe ser compatible con versión de Xcode

### Error: "Code signing failed"
- Abrir `ios/Runner.xcworkspace` en Xcode
- Cambiar Bundle Identifier a algo único
- Seleccionar tu Team (Apple ID)

---

## 📞 Contacto

Si necesitas ayuda durante la transferencia:
- Revisar `docs/IOS_SETUP_GUIDE.md` (guía completa)
- Ejecutar `flutter doctor -v` y compartir output
- Revisar logs de Xcode

---

**¡Listo para probar en iPhone!** 🚀📱
