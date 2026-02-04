# ✅ Checklist - Preparación para Pruebas en iPhone

Usa esta lista para asegurar que todo está listo antes de transferir el proyecto a la MacBook.

## 📦 Archivos del Proyecto

### Código y Configuración
- [x] `lib/` - Código fuente completo
- [x] `ios/` - Carpeta iOS creada ⭐
- [x] `ios/Podfile` - Configurado ⭐
- [x] `ios/Runner/Info.plist` - Permisos agregados ⭐
- [x] `android/` - Carpeta Android
- [x] `pubspec.yaml` - Dependencias actualizadas
- [x] `.env` - Variables de Supabase configuradas
- [ ] `.env` tiene las credenciales CORRECTAS de producción

### Documentación
- [x] `README.md` - Documentación principal ⭐
- [x] `TRANSFER_TO_MAC.md` - Guía de transferencia ⭐
- [x] `docs/IOS_SETUP_GUIDE.md` - Guía completa de iOS ⭐
- [x] `docs/PRODUCCION_CHECKLIST.md` - Checklist de producción
- [x] `database/README.md` - Instrucciones de SQL
- [x] `scripts/README.md` - Documentación de scripts

### Scripts
- [x] `scripts/setup_ios.sh` - Script de setup para Mac ⭐
- [x] `scripts/install_dependencies.bat` - Para Windows
- [x] Script de setup tiene permisos de ejecución (se hace en Mac)

## 🔧 Verificación en Windows

### Build y Análisis
```powershell
# 1. Limpiar builds previos
flutter clean

# 2. Obtener dependencias
flutter pub get

# 3. Analizar código (debe mostrar "No issues found!")
flutter analyze

# 4. Ejecutar tests
flutter test
```

- [ ] `flutter analyze` = 0 issues ✅
- [ ] `flutter test` = All tests passed ✅

### Variables de Entorno
- [ ] Archivo `.env` existe en la raíz
- [ ] `SUPABASE_URL` está configurado
- [ ] `SUPABASE_ANON_KEY` está configurado
- [ ] Las credenciales son del proyecto de PRODUCCIÓN (no dev)

## 🗄️ Configuración de Supabase

### Scripts SQL Ejecutados
- [ ] `supabase_schema.sql` ejecutado en Supabase
- [ ] `supabase_rls_policies.sql` ejecutado
- [ ] `storage_policies.sql` ejecutado
- [ ] `delete_account_function.sql` ejecutado

### Verificar en Dashboard
- [ ] Las 9 tablas existen en Database
- [ ] RLS está habilitado en todas las tablas (candado 🔒)
- [ ] Los 3 buckets de Storage existen:
  - [ ] `profile-photos`
  - [ ] `exercise-videos`
  - [ ] `exercise-thumbnails`

### Authentication
- [ ] Email provider está activado
- [ ] Redirect URLs configuradas:
  - [ ] `io.supabase.chamosfitness://login-callback`

## 📱 Preparación del iPhone

### Antes de Conectar
- [ ] iPhone desbloqueado
- [ ] iOS 12 o superior
- [ ] Espacio de almacenamiento > 500MB
- [ ] Batería > 50%

### Configuración
- [ ] **Ajustes → General → Transferir o Restablecer → Modo de Desarrollador**
  - [ ] Modo de Desarrollador ACTIVADO
- [ ] iPhone reiniciado después de activar Modo de Desarrollador

### Cable
- [ ] Cable USB-C o Lightning disponible
- [ ] Cable es original o certificado (MFi)

## 💻 Preparación de la MacBook

### Software Requerido
- [ ] macOS Monterey o superior
- [ ] Xcode instalado (desde App Store)
- [ ] Xcode Command Line Tools instalados
- [ ] Flutter instalado
- [ ] CocoaPods instalado (`pod --version`)

### Verificación
```bash
# Ejecutar en MacBook antes de transferir:
flutter doctor -v

# Verificar que todo esté ✓
```

## 🔄 Método de Transferencia Elegido

Marcar el método que usarás:

- [ ] **GitHub** (recomendado)
  - [ ] Repositorio creado en GitHub
  - [ ] Código pusheado: `git push origin main`
  - [ ] URL del repo anotada: ____________________________

- [ ] **Carpeta Comprimida**
  - [ ] Ejecutado `flutter clean` antes de comprimir
  - [ ] ZIP creado (< 50MB preferiblemente)
  - [ ] ZIP probado (descomprimir para verificar)

- [ ] **AirDrop** (solo Mac a Mac)
  - [ ] AirDrop activado en ambas Macs
  - [ ] Macs cercanas (< 10 metros)

## 📋 En la MacBook (Checklist de Ejecución)

Una vez transferido el proyecto:

```bash
# 1. Ir al proyecto
cd ~/Developer/chamos-fitness-center

# 2. Verificar archivos
ls -la

# 3. Dar permisos al script
chmod +x scripts/setup_ios.sh

# 4. Ejecutar setup
./scripts/setup_ios.sh

# 5. Conectar iPhone

# 6. Ejecutar app
flutter run
```

### Primera Ejecución
- [ ] Script `setup_ios.sh` ejecutado sin errores
- [ ] CocoaPods instaló correctamente (`pod install`)
- [ ] `flutter doctor` muestra todo en ✓
- [ ] iPhone aparece en `flutter devices`

### En Xcode
- [ ] Abrió `ios/Runner.xcworkspace` (NO .xcodeproj)
- [ ] Seleccionado el Team (Apple ID)
- [ ] Bundle Identifier único configurado
- [ ] "Automatically manage signing" activado
- [ ] Build exitoso (⌘ + B)

## 🧪 Pruebas Iniciales en iPhone

Una vez que la app corra:

### Funcionalidades Básicas
- [ ] App se instala sin errores
- [ ] App abre correctamente
- [ ] Splash screen se muestra
- [ ] Login screen aparece
- [ ] No hay crashes inmediatos

### Permisos
Al intentar usar cada feature por primera vez:
- [ ] Permiso de cámara solicitado
- [ ] Permiso de galería solicitado
- [ ] Permiso de notificaciones solicitado
- [ ] Todos los permisos se pueden otorgar

### Supabase
- [ ] Login funciona
- [ ] Registro funciona
- [ ] Datos se cargan desde Supabase
- [ ] Imágenes se suben a Storage

## 📸 Capturas para Debugging

Si hay errores, capturar:

- [ ] Screenshot del error en iPhone
- [ ] Logs de `flutter run -v`
- [ ] Logs de Xcode (Debug Area)
- [ ] Output de `flutter doctor -v`

## ✅ Todo Listo para Transferir

Una vez completados todos los checkboxes arriba:

```bash
# Último comando antes de transferir (en Windows):
git status
git add .
git commit -m "chore: ready for iOS testing on iPhone"
git push
```

---

## 📞 Soporte

Si algo falla:

1. Revisar `docs/IOS_SETUP_GUIDE.md` sección "Problemas Comunes"
2. Ejecutar `flutter doctor -v` y copiar output
3. Revisar logs de Xcode para mensajes de error específicos

---

**Fecha de preparación:** _______________

**Preparado por:** _______________

**Listo para transferir:** ☐ SÍ  ☐ NO

---

**¡Buena suerte con las pruebas en iPhone!** 🚀📱
