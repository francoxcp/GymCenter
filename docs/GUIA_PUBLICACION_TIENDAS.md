# Guía Completa de Publicación — Chamos Fitness Center

**App:** Chamos Fitness Center  
**Bundle ID / Package:** `com.chamosfitness.app`  
**Versión inicial:** `1.0.0` (versionCode 1)  
**Última actualización de esta guía:** Febrero 2026

---

## ÍNDICE

1. [Prerequisitos generales](#1-prerequisitos-generales)
2. [Configuración de credenciales (obligatorio)](#2-configuración-de-credenciales-obligatorio)
3. [Configuración del ícono y nombre de la app](#3-configuración-del-ícono-y-nombre-de-la-app)
4. [Preparar la política de privacidad pública](#4-preparar-la-política-de-privacidad-pública)
5. [ANDROID — Google Play Store](#5-android--google-play-store)
6. [iOS — Apple App Store](#6-ios--apple-app-store)
7. [Cómo publicar actualizaciones](#7-cómo-publicar-actualizaciones)
8. [Solución de problemas frecuentes](#8-solución-de-problemas-frecuentes)

---

## 1. Prerequisitos generales

### Software necesario

| Herramienta | Versión mínima | Para qué |
|---|---|---|
| Flutter SDK | 3.x | Compilar la app |
| Java JDK | 17 o 21 | Build de Android |
| Android Studio | Cualquier reciente | Emulador y tools |
| Xcode (solo Mac) | 15+ | Compilar iOS |
| Git | Cualquiera | Versión del código |

### Verificar instalación

Abre PowerShell (Windows) o Terminal (Mac) y ejecuta:

```bash
flutter doctor -v
```

Todos los ítems deben aparecer en verde o con advertencias menores. Si alguno está en rojo, sigue las instrucciones que da el mismo comando.

---

## 2. Configuración de credenciales (obligatorio)

Las credenciales de Supabase NO están dentro del código fuente (por seguridad). Se inyectan en el momento de compilar. **Sin este paso, la app no se conecta al backend.**

### 2.1 Crear el archivo de credenciales locales

1. Ve a la carpeta `scripts/` del proyecto
2. Copia el archivo `local_credentials.bat.example` y renómbralo como `local_credentials.bat`

   ```
   scripts/
   ├── local_credentials.bat.example   ← plantilla (está en Git)
   └── local_credentials.bat           ← TU archivo real (NO en Git)
   ```

3. Abre `local_credentials.bat` con el Bloc de Notas y rellena tus datos:

   ```bat
   set SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
   set SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxx
   ```

### 2.2 ¿Dónde encontrar estas credenciales?

1. Ve a [supabase.com](https://supabase.com) e inicia sesión
2. Selecciona tu proyecto **Chamos Fitness Center**
3. En el menú izquierdo: **Settings → API**
4. Copia:
   - **Project URL** → es el `SUPABASE_URL`
   - **Project API Keys → anon (public)** → es el `SUPABASE_ANON_KEY`

> ⚠️ Nunca uses la `service_role` key en la app móvil. Solo la `anon`.

---

## 3. Configuración del ícono y nombre de la app

### 3.1 Ícono de la app

El ícono fuente está en `assets/icons/app_icon.png`.

Requisitos del archivo fuente:
- Tamaño: **1024×1024 px** mínimo (recomendado)
- Formato: PNG
- Fondo: Negro (`#000000`) o el color de tu marca
- Sin transparencia en Android (la transparencia causa fondo negro en algunos dispositivos)

Para regenerar todos los tamaños de íconos automáticamente:

```bash
flutter pub run flutter_launcher_icons
```

Esto genera automáticamente todos los tamaños para Android e iOS.

### 3.2 Nombre de la app

- **Android:** El nombre que ve el usuario está en `android/app/src/main/AndroidManifest.xml`, línea `android:label="Chamos Fitness"`
- **iOS:** Está en `ios/Runner/Info.plist`, clave `CFBundleDisplayName`

Si quieres cambiar el nombre que aparece bajo el ícono, edita ambos archivos.

---

## 4. Preparar la política de privacidad pública

Tanto Google como Apple **exigen** una URL pública de política de privacidad. El archivo ya existe en el proyecto: `web_deploy/privacy.html`.

### Opción A — GitHub Pages (gratis, 10 minutos)

1. Crea una cuenta en [github.com](https://github.com) si no tienes
2. Crea un repositorio nuevo, llámalo `chamos-legal`
3. Sube el archivo `web_deploy/privacy.html` como `index.html`
4. En el repositorio: **Settings → Pages → Source: main branch → Save**
5. Tu URL será: `https://TU_USUARIO.github.io/chamos-legal/`

### Opción B — Netlify (gratis, 5 minutos)

1. Ve a [netlify.com](https://netlify.com)
2. Arrastra la carpeta `web_deploy/` al área de drop
3. Obtienes una URL del tipo `https://nombre-aleatorio.netlify.app`

> Guarda esta URL, la necesitarás al completar el listing en ambas tiendas.

---

## 5. ANDROID — Google Play Store

### 5.1 Crear la cuenta de desarrollador (una sola vez)

1. Ve a [play.google.com/console](https://play.google.com/console)
2. Inicia sesión con una cuenta de Google (preferiblemente la del negocio)
3. Paga el registro: **US$25 pago único**
4. Completa tu perfil de desarrollador (nombre, dirección, teléfono)
5. La cuenta puede tardar **24-48 horas** en ser verificada

### 5.2 Crear el Keystore de firma (una sola vez en la vida del proyecto)

El keystore es el certificado digital que identifica tu app. **Si lo pierdes, no puedes publicar actualizaciones.** Guárdalo en al menos 2 lugares seguros (Google Drive personal, USB).

Abre PowerShell y ejecuta:

```bat
keytool -genkey -v ^
  -keystore chamos-release.jks ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000 ^
  -alias chamos
```

El comando te pedirá:
- **Contraseña del keystore:** Elige una segura, escríbela en un lugar seguro
- **Nombre y apellido:** Pon el nombre de la empresa o el tuyo
- **Unidad organizativa:** Puedes poner "Mobile"
- **Organización:** "Chamos Fitness Center"
- **Ciudad / Estado / País:** Los tuyos (ej: Caracas / Miranda / VE)
- **Contraseña del alias:** Puede ser la misma que la del keystore

Mueve el archivo generado a `android/app/`:

```bat
move chamos-release.jks d:\ChamosFitnessCenter\android\app\chamos-release.jks
```

### 5.3 Crear el archivo `key.properties`

Crea el archivo `android/key.properties` (ya está en `.gitignore`, no te preocupes) con este contenido:

```properties
storePassword=LA_CONTRASEÑA_DEL_KEYSTORE
keyPassword=LA_CONTRASEÑA_DEL_ALIAS
keyAlias=chamos
storeFile=chamos-release.jks
```

> ⚠️ Cambia los valores por las contraseñas que pusiste al crear el keystore.

### 5.4 Compilar el App Bundle (AAB)

Google Play **solo acepta el formato AAB** (App Bundle), no APK sueltos. Ejecuta:

```bat
flutter build appbundle --release ^
  --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=tu-anon-key ^
  --obfuscate ^
  --split-debug-info=build/debug-info
```

O si usas el script automático:

```bat
cd d:\ChamosFitnessCenter\scripts
build_production.bat
```
*(selecciona opción 2 — App Bundle)*

El archivo resultante estará en:
```
build\app\outputs\bundle\release\app-release.aab
```

### 5.5 Verificar el AAB antes de subir

```bat
flutter install --release
```
Instala la versión release en un dispositivo conectado o emulador para hacer una prueba final rápida.

### 5.6 Crear la app en Google Play Console

1. En Play Console, clic en **"Crear app"**
2. Nombre de la app: `Chamos Fitness Center`
3. Idioma predeterminado: **Español (España)** o **Español (Latinoamérica)**
4. App o juego: **App**
5. Gratis o de pago: **Gratis**
6. Acepta las declaraciones y clic en **"Crear app"**

### 5.7 Completar el listing (ficha de Play Store)

Ve a **"Presencia en Play Store" → "Ficha de Play Store principal"**:

| Campo | Qué poner |
|---|---|
| Nombre de la app | `Chamos Fitness Center` |
| Descripción corta (80 chars) | `Rutinas, nutrición y seguimiento para tu transformación fitness` |
| Descripción larga | Descripción detallada de todas las funciones (mínimo 500 caracteres) |
| Ícono | PNG 512×512 px (sin transparencia) |
| Gráfico de función | JPG/PNG 1024×500 px |
| Capturas de teléfono | Mínimo 2, máximo 8. Tamaño: 1080×1920 px recomendado |
| Tipo de la app | Salud y forma física |
| Categoría | Salud y forma física |
| Dirección de email | Tu email de contacto |
| Política de privacidad | URL de la política que subiste en el Paso 4 |

### 5.8 Configurar el contenido de la app

Ve a **"Contenido de la app"** y completa:

- **Calificación de contenido:** Responde el cuestionario (la app probablemente obtendrá PEGI 3 / Everyone)
- **Público objetivo:** 18+ (gym app)
- **Acceso a la app:** Proporciona credenciales de prueba para los revisores (crea una cuenta de prueba en tu app)
- **Anuncios:** "No contiene anuncios"
- **Seguridad de los datos:** Declara qué datos recopila (nombre, email, fotos de perfil, datos de salud/fitness)

### 5.9 Subir el AAB

Ve a **"Versiones de la app" → "Producción" → "Crear nueva versión"**:

1. Si es tu primera vez, Google te ofrecerá **Play App Signing** — **acepta siempre**. Google protege tu clave y la puede recuperar si la pierdes.
2. Sube el archivo `app-release.aab`
3. En "Novedades de esta versión": `Versión inicial de Chamos Fitness Center`
4. Clic en **"Guardar"** y luego **"Revisar versión"**

### 5.10 Enviar a revisión

1. Revisa que todos los semáforos estén en verde en el dashboard
2. Clic en **"Enviar a producción"**
3. La revisión tarda **3 a 7 días hábiles** la primera vez

Recibirás un email cuando sea aprobada o si necesita cambios.

---

## 6. iOS — Apple App Store

> ⚠️ **Requiere una Mac con Xcode.** No se puede compilar para iOS desde Windows.  
> Si no tienes Mac, usa [Codemagic](https://codemagic.io) (plan gratuito disponible para Flutter).

### 6.1 Crear la cuenta Apple Developer (una sola vez)

1. Ve a [developer.apple.com/programs](https://developer.apple.com/programs/enroll/)
2. Inicia sesión con tu Apple ID (o crea uno)
3. Selecciona **"Individual"** (o "Organization" si es empresa)
4. Paga la suscripción: **US$99 al año** (se renueva anualmente)
5. La verificación puede tardar **24-48 horas**

### 6.2 Registrar el Bundle Identifier

1. Ve a [developer.apple.com/account](https://developer.apple.com/account)
2. **Certificates, Identifiers & Profiles → Identifiers → (+)**
3. Selecciona **"App IDs"** → **"App"**
4. Bundle ID: `com.chamosfitness.app` (modo **Explicit**)
5. Activa las capacidades necesarias:
   - **Push Notifications** (si usas notificaciones)
   - **Sign In with Apple** (requerido si tu app tiene login social)
6. Registrar

### 6.3 Crear el certificado de distribución

En **Certificates → (+)**:
1. Selecciona **"Apple Distribution"**
2. Sigue los pasos para generar un CSR desde tu Mac (Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority)
3. Sube el CSR y descarga el certificado
4. Haz doble clic en el `.cer` descargado para instalarlo en tu Mac

### 6.4 Crear el Provisioning Profile

En **Profiles → (+)**:
1. Selecciona **"App Store Connect"**
2. Selecciona el App ID `com.chamosfitness.app`
3. Selecciona tu certificado de distribución
4. Nombre del perfil: `ChamosFitness AppStore`
5. Descarga e instala el `.mobileprovision` (doble clic)

### 6.5 Crear la app en App Store Connect

1. Ve a [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **"Mis apps" → (+) → "Nueva app"**
3. Plataformas: **iOS**
4. Nombre: `Chamos Fitness Center`
5. Idioma principal: **Español (México)** o **Español**
6. Bundle ID: selecciona `com.chamosfitness.app` (aparece si lo registraste)
7. SKU: `chamosfitnesscenter` (identificador interno, no visible al público)
8. Acceso de usuario: **Acceso completo**

### 6.6 Completar el listing (ficha de App Store)

Ve a **"App Store" → "Información de la app"** y **"iOS App"**:

| Campo | Qué poner |
|---|---|
| Nombre | `Chamos Fitness Center` |
| Subtítulo | `Tu gym en el bolsillo` |
| Categoría principal | Salud y forma física |
| Descripción | Descripción completa de la app |
| Palabras clave | `gym,fitness,rutinas,ejercicios,nutrición,entrenamiento` (máx 100 chars) |
| URL de soporte | Tu email o página web |
| URL de privacidad | URL de la política subida en el Paso 4 |
| Capturas de iPhone | Para dispositivos 6.5" (1284×2778) y 5.5" (1242×2208) — ambos obligatorios |

### 6.7 Compilar y subir el IPA (desde Mac o CI/CD)

**Desde Mac por terminal:**

```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=tu-anon-key \
  --obfuscate \
  --split-debug-info=build/debug-info
```

Luego abrir Xcode:
1. `open ios/Runner.xcworkspace`
2. **Product → Archive**
3. Cuando termine: **Distribute App → App Store Connect → Upload**

**O desde Xcode directamente:**
1. Asegúrate de que el scheme esté en **"Release"**
2. Conecta un dispositivo físico o selecciona "Any iOS Device"
3. **Product → Archive → Distribute App → App Store Connect**

**Usando Codemagic (sin Mac):**
1. Crea cuenta en [codemagic.io](https://codemagic.io)
2. Conecta tu repositorio de GitHub/GitLab
3. Configura las variables de entorno con tus credenciales de Supabase
4. Codemagic compila y sube automáticamente a TestFlight

### 6.8 TestFlight — pruebas antes de publicar

Una vez subido el IPA, en App Store Connect:

1. Ve a **"TestFlight"** → tu build aparecerá procesándose (5-10 min)
2. Agrega testers internos (tu equipo, máx 100 personas)
3. Prueba la app durante unos días
4. Para testers externos: se necesita una **revisión de TestFlight** por Apple (~24h)

### 6.9 Enviar a revisión de App Store

1. En App Store Connect → **"Versión de iOS 1.0.0"**
2. Selecciona el build que subiste desde TestFlight
3. Completa la sección **"Información de la app" → "Sign-In Information"**: proporciona un usuario y contraseña de prueba para que el revisor de Apple pueda probar la app
4. Responde las preguntas de **"Notas adicionales"** si las tiene
5. Clic en **"Agregar a revisión"** → **"Enviar para revisión"**
6. La revisión tarda **1 a 3 días hábiles**

---

## 7. Cómo publicar actualizaciones

### Cada vez que hagas cambios que quieras publicar:

**Paso 1: Subir la versión en `pubspec.yaml`**

```yaml
# Antes:
version: 1.0.0+1

# Después:
version: 1.0.1+2
```

El número antes del `+` es la versión visible al usuario (`versionName`).  
El número después del `+` es el código interno incremental (`versionCode`). Debe subir siempre.

**Paso 2: Compilar**

```bat
# Android
flutter build appbundle --release ^
  --dart-define=SUPABASE_URL=... ^
  --dart-define=SUPABASE_ANON_KEY=...

# iOS (desde Mac)
flutter build ipa --release ^
  --dart-define=SUPABASE_URL=... ^
  --dart-define=SUPABASE_ANON_KEY=...
```

**Paso 3: Subir**

- **Android:** Play Console → Producción → Crear nueva versión → subir el nuevo `.aab`
- **iOS:** App Store Connect → (+) nueva versión → subir el nuevo build desde Xcode

**Paso 4: Esperar revisión**

- Google: 1-3 días (actualizaciones son más rápidas que la primera)
- Apple: 1-2 días (también más rápidas en actualizaciones)

---

## 8. Solución de problemas frecuentes

### Android

**Error: "keystore file not found"**
- Verifica que `android/app/chamos-release.jks` existe
- Verifica que las rutas en `android/key.properties` son correctas
- El `storeFile` debe ser la ruta relativa desde `android/app/`, por ejemplo: `chamos-release.jks`

**Error: "SUPABASE_URL is empty"**
- La app fue compilada sin los `--dart-define`
- Asegúrate de incluir ambos `--dart-define` en el comando de build

**Error en Play Console: "You uploaded an APK..."**
- Debes subir un AAB, no un APK
- Usa `flutter build appbundle`, no `flutter build apk`

**Error: "versionCode already used"**
- El `versionCode` (número después del `+` en pubspec.yaml) ya fue usado antes
- Incrementa ese número: `1.0.0+2` → `1.0.0+3`

### iOS

**Error: "No signing certificate"**
- El certificado de distribución no está instalado en tu Mac
- Descárgalo de developer.apple.com y haz doble clic para instalarlo

**Error: "Provisioning profile not found"**
- El perfil de aprovisionamiento no coincide con el Bundle ID
- Verifica que el Bundle ID en Xcode es exactamente `com.chamosfitness.app`

**Rechazo: "Missing privacy usage description"**
- El Info.plist ya tiene las descripciones de permisos
- Si añades nuevas funcionalidades que usen cámara/fotos/micrófono, agrega la descripción correspondiente en `ios/Runner/Info.plist`

**Rechazo: "App uses encryption"**
- Necesitas declarar el uso de cifrado en App Store Connect
- Por usar HTTPS/TLS: selecciona "Sí, usa cifrado estándar" y marca la exención

---

## Resumen de costos

| Servicio | Costo | Periodicidad |
|---|---|---|
| Google Play Console | US$25 | Único |
| Apple Developer Program | US$99 | Anual |
| Supabase (backend) | Gratis (Free tier) | Mensual |
| GitHub Pages (privacidad) | Gratis | — |
| Codemagic CI/CD (opcional) | Gratis (500 min/mes) | Mensual |

---

## Archivos importantes del proyecto

| Archivo | Para qué |
|---|---|
| `pubspec.yaml` | Versión de la app (`version: 1.0.0+1`) |
| `android/app/build.gradle` | Package name, versionCode, firma |
| `android/key.properties` | Contraseñas del keystore (NO subir a Git) |
| `android/app/chamos-release.jks` | Keystore de firma Android (NO subir a Git) |
| `ios/Runner/Info.plist` | Bundle ID, nombre, permisos iOS |
| `assets/icons/app_icon.png` | Ícono fuente de la app |
| `web_deploy/privacy.html` | Política de privacidad para subir online |
| `scripts/local_credentials.bat` | Credenciales Supabase locales (NO subir a Git) |
| `scripts/build_production.bat` | Script de compilación todo-en-uno |

---

*Guía generada para el proyecto Chamos Fitness Center — Febrero 2026*
