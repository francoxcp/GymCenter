# Guía de Configuración iOS para Chamos Fitness Center

## 📱 Requisitos Previos

### En la MacBook:

1. **macOS Monterey o superior** (recomendado macOS Ventura/Sonoma)
2. **Xcode 14.0 o superior** (descargar desde App Store)
3. **CocoaPods instalado**
4. **Flutter instalado y configurado**
5. **Cuenta de Apple Developer** (para probar en dispositivo físico)

---

## 🚀 Pasos de Configuración

### 1. Transferir el Proyecto a la MacBook

**Opción A: GitHub (Recomendado)**
```bash
# En Windows, pushear el proyecto
git init
git add .
git commit -m "Initial commit - iOS ready"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/chamos-fitness.git
git push -u origin main

# En MacBook, clonar
git clone https://github.com/TU_USUARIO/chamos-fitness.git
cd chamos-fitness
```

**Opción B: USB o AirDrop**
- Copiar toda la carpeta `ChamosFitnessCenter` a la MacBook
- Ubicarla en `~/Developer/chamos-fitness-center`

---

### 2. Verificar Flutter en MacBook

```bash
# Verificar instalación de Flutter
flutter doctor -v

# Debes ver:
# ✓ Flutter (Channel stable)
# ✓ Xcode - develop for iOS and macOS
# ✓ CocoaPods version X.X.X
```

**Si falta CocoaPods:**
```bash
sudo gem install cocoapods
```

**Si hay problemas con Xcode:**
```bash
# Aceptar licencia de Xcode
sudo xcodebuild -license accept

# Instalar Command Line Tools
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

---

### 3. Instalar Dependencias del Proyecto

```bash
cd ~/Developer/chamos-fitness-center

# Limpiar instalaciones previas (por si acaso)
flutter clean

# Instalar dependencias de Flutter
flutter pub get

# Ir a la carpeta iOS
cd ios

# Instalar CocoaPods (esto puede tardar 5-10 minutos la primera vez)
pod install

# Si hay errores, intentar:
pod repo update
pod install --repo-update

# Volver a la raíz del proyecto
cd ..
```

---

### 4. Configurar el Proyecto en Xcode

#### 4.1 Abrir el Workspace (NO el .xcodeproj)
```bash
open ios/Runner.xcworkspace
```

#### 4.2 Configurar Signing & Capabilities

En Xcode:

1. **Seleccionar el proyecto "Runner"** en el navegador izquierdo
2. **Seleccionar el target "Runner"** 
3. **Ir a "Signing & Capabilities"**

**Configuración:**
- **Team:** Seleccionar tu Apple ID / Team
- **Bundle Identifier:** `com.chamosfitness.chamos-fitness-center`
  - Si ya existe, cambiar a: `com.chamosfitness.chamos-fitness-center.dev`
- **Signing Certificate:** Apple Development
- **Automatically manage signing:** ✅ Activado

#### 4.3 Verificar Capabilities

Asegurar que estén agregadas:
- ✅ **App Groups** (si usas compartir datos)
- ✅ **Push Notifications** (para notificaciones)
- ✅ **Background Modes** → Background fetch, Remote notifications

---

### 5. Conectar iPhone a la MacBook

#### 5.1 Preparar el iPhone

**En el iPhone:**
1. Ir a **Ajustes → General → Transferir o Restablecer iPhone → Restablecer → Restablecer Ubicación y Privacidad** (opcional, limpia permisos)
2. Ir a **Ajustes → Privacidad y Seguridad → Modo de Desarrollador**
3. **Activar "Modo de Desarrollador"**
4. Reiniciar el iPhone

#### 5.2 Confiar en el Mac

1. Conectar iPhone con cable USB-C o Lightning
2. Desbloquear iPhone
3. Aparecerá un popup: **"¿Confiar en este ordenador?"** → **Confiar**
4. En Xcode, aparecerá el iPhone en la lista de dispositivos

---

### 6. Ejecutar la App en el iPhone

#### Opción A: Desde VS Code (Recomendado)

```bash
# Listar dispositivos conectados
flutter devices

# Debes ver algo como:
# iPhone de TuNombre (mobile) • 00008030-XXXXXXXXXX • ios • iOS 17.2.1

# Ejecutar en el iPhone conectado
flutter run
```

#### Opción B: Desde Xcode

1. En Xcode, seleccionar tu iPhone en la barra superior (junto al botón de play)
2. Presionar el botón ▶️ **Run**
3. Esperar la compilación (primera vez puede tardar 5-10 minutos)

#### Opción C: Desde Terminal

```bash
# Ejecutar directamente
flutter run -d <DEVICE_ID>

# O simplemente (seleccionará el iPhone automáticamente)
flutter run
```

---

## ⚠️ Problemas Comunes y Soluciones

### Error: "Failed to build iOS app"

**Solución:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

---

### Error: "Code signing required"

**Solución:**
1. Abrir `ios/Runner.xcworkspace` en Xcode
2. Seleccionar el target "Runner"
3. En "Signing & Capabilities":
   - Cambiar el Bundle Identifier a algo único: `com.TU_NOMBRE.chamos-fitness`
   - Seleccionar tu Team (Apple ID)
   - Asegurar que "Automatically manage signing" esté activado

---

### Error: "Developer Mode disabled"

**Solución en iPhone:**
1. Ajustes → Privacidad y Seguridad
2. Modo de Desarrollador → Activar
3. Reiniciar iPhone

---

### Error: "Untrusted Developer"

Cuando ejecutas la app por primera vez en el iPhone:

1. Aparecerá un mensaje: **"Desarrollador empresarial no verificado"**
2. En el iPhone: **Ajustes → General → VPN y Gestión de Dispositivos**
3. Seleccionar tu Apple ID
4. **Confiar en "[Tu Apple ID]"**
5. Volver a ejecutar la app

---

### Error: "Could not find a valid Xcode"

**Solución:**
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

---

### App se cierra inmediatamente al abrir

**Posibles causas:**

1. **Permisos no otorgados:**
   - En iPhone: Ajustes → Chamos Fitness → Permitir Cámara, Fotos, Notificaciones

2. **Variables de entorno faltantes:**
   - Verificar que el archivo `.env` existe en la raíz del proyecto
   - Debe contener `SUPABASE_URL` y `SUPABASE_ANON_KEY`

3. **Problemas de Supabase:**
   - Verificar conexión a internet
   - Verificar que las URLs de Supabase sean correctas

---

## 🧪 Testing en Dispositivo Real

### Hot Reload y Hot Restart

Mientras la app está corriendo:

- **Hot Reload (r):** Actualiza la UI sin perder el estado
- **Hot Restart (R):** Reinicia la app desde cero
- **Quit (q):** Detener la app

```bash
# En la terminal donde corre flutter run:
r   # Hot reload
R   # Hot restart  
q   # Quit
```

---

### Debugging

#### Ver logs en tiempo real:
```bash
flutter logs
```

#### Abrir DevTools:
```bash
flutter pub global activate devtools
flutter pub global run devtools

# En otra terminal:
flutter run --observatory-port=9200
```

---

## 📦 Build de Release para Testing

### Build para TestFlight / AdHoc

```bash
# Crear IPA de release
flutter build ipa --release

# El archivo .ipa estará en:
# build/ios/ipa/chamos_fitness_center.ipa
```

### Subir a TestFlight (Requiere cuenta Apple Developer de pago)

1. Abrir Xcode → **Product → Archive**
2. Una vez creado el Archive → **Distribute App**
3. Seleccionar **TestFlight & App Store**
4. Seguir los pasos del wizard
5. Subir a App Store Connect

---

## 🎯 Checklist de Pruebas en iPhone

### Funcionalidades Básicas
- [ ] Login y registro funcionan
- [ ] Recuperación de contraseña funciona
- [ ] Navegación entre pantallas fluida
- [ ] Onboarding se muestra correctamente

### Permisos
- [ ] Solicitud de permiso de cámara funciona
- [ ] Tomar foto de perfil funciona
- [ ] Seleccionar desde galería funciona
- [ ] Notificaciones locales funcionan

### Supabase
- [ ] Conexión a Supabase exitosa
- [ ] Autenticación funciona
- [ ] Consultas a base de datos funcionan
- [ ] Subida de imágenes funciona (Storage)

### UI/UX
- [ ] Orientación bloqueada a Portrait
- [ ] Safe Areas correctas (no hay contenido bajo el notch)
- [ ] Teclado sube/baja correctamente
- [ ] Loading states se muestran bien
- [ ] Errores se muestran con SnackBars

### Performance
- [ ] Transiciones suaves (60 FPS)
- [ ] Imágenes cargan rápido
- [ ] No hay lags en scrolling
- [ ] Memoria no aumenta descontroladamente

---

## 📱 Configuración Adicional para Supabase en iOS

### Deep Linking para OAuth

Si usas login con Google/Apple:

1. En **Supabase Dashboard → Authentication → URL Configuration:**
   - **Redirect URLs:** Agregar: `io.supabase.chamosfitness://login-callback`

2. Ya está configurado en `Info.plist` (URL Schemes)

---

## 🔧 Comandos Útiles

```bash
# Ver dispositivos conectados
flutter devices

# Ejecutar en modo release
flutter run --release

# Ver logs detallados
flutter run -v

# Analizar tamaño del IPA
flutter build ipa --analyze-size

# Limpiar todo y reconstruir
flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter run

# Ver información de Flutter Doctor
flutter doctor -v
```

---

## 📞 Soporte

Si encuentras problemas:

1. Ejecutar `flutter doctor -v` y copiar el output
2. Ejecutar `flutter run -v` y copiar los errores
3. Revisar logs en Xcode: **View → Debug Area → Show Debug Area**

---

## ✅ Todo Listo

Una vez que la app corra en el iPhone:

1. Probar todas las funcionalidades
2. Tomar screenshots para las tiendas
3. Grabar videos de demostración
4. Identificar bugs específicos de iOS
5. Ajustar UI si es necesario (Safe Areas, tamaños, etc.)

**¡Buena suerte con las pruebas!** 🚀
