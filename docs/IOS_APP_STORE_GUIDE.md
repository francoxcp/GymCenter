# 🍎 GUÍA DE PUBLICACIÓN EN APPLE APP STORE
## Chamos Fitness Center - iOS

**Última actualización:** 11 de febrero de 2026  
**Versión:** 1.0.0  
**Estado:** 🔧 Requiere Mac para completar

---

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Actualizar Bundle Identifier](#paso-1-actualizar-bundle-identifier)
3. [Configurar Apple Developer Account](#paso-2-configurar-apple-developer-account)
4. [Configurar Signing en Xcode](#paso-3-configurar-signing-en-xcode)
5. [Build IPA](#paso-4-build-ipa)
6. [Crear App en App Store Connect](#paso-5-crear-app-en-app-store-connect)
7. [Preparar Assets](#paso-6-preparar-assets)
8. [Configurar Metadata](#paso-7-configurar-metadata)
9. [App Privacy](#paso-8-app-privacy)
10. [Subir Build](#paso-9-subir-build)
11. [TestFlight](#paso-10-testflight)
12. [Submit for Review](#paso-11-submit-for-review)
13. [Post-Launch](#paso-12-post-launch)

---

## ⚙️ Requisitos Previos

### ✅ Hardware y Software OBLIGATORIOS

**⚠️ IMPORTANTE:** No puedes publicar en App Store sin estos requisitos:

1. **Mac con macOS 12.0 (Monterey) o superior**
   - MacBook, iMac, Mac Mini, Mac Studio
   - Windows NO es compatible

2. **Xcode 14.0 o superior**
   - Descarga GRATIS desde App Store en Mac
   - ~15 GB de espacio en disco
   - Tiempo de descarga: 30 min - 2 horas

3. **Apple Developer Account** 
   - Costo: **$99 USD/año**
   - Inscripción: https://developer.apple.com/programs/
   - Verificación: 24-48 horas

4. **CocoaPods**
   ```bash
   # En Mac Terminal
   sudo gem install cocoapods
   ```

### 💳 Crear Apple Developer Account

1. Ve a [Apple Developer](https://developer.apple.com/programs/)
2. Click **"Enroll"**
3. Login con tu Apple ID
4. Selecciona tipo de cuenta:
   - **Individual:** Persona física ($99/año)
   - **Organization:** Empresa ($99/año, requiere D-U-N-S)
5. Completa información personal/empresa
6. Pago con tarjeta de crédito/débito
7. Acepta términos del programa
8. Espera confirmación por email (24-48 horas)

⏱️ **Tiempo de activación:** 1-3 días laborables

---

## 📱 Configuración Actual del Proyecto

### Bundle Identifier Actual:

```
com.chamosfitness.chamosFitnessCenterTemp
```

**Estado:** ❌ Temporal, debe cambiarse a producción

### Bundle Identifier para Producción:

```
com.chamosfitness.app
```

**Este ID debe coincidir en:**
- Xcode project settings
- Apple Developer Portal
- App Store Connect

---

## 🔧 Paso 1: Actualizar Bundle Identifier

### ⚠️ CRÍTICO: Solo en Mac

Este paso **SOLO** se puede hacer en Mac con Xcode instalado.

### 1.1 Abrir Proyecto en Xcode

```bash
# En Mac Terminal, navega al proyecto
cd /ruta/donde/clonaste/ChamosFitnessCenter

# Abre el workspace (NO el .xcodeproj)
open ios/Runner.xcworkspace
```

**IMPORTANTE:** Siempre abre `.xcworkspace`, NO `.xcodeproj`

### 1.2 Seleccionar Target

En Xcode:
1. Panel izquierdo → Click en **"Runner"** (carpeta azul con ícono de app)
2. Asegúrate que esté seleccionado el target **"Runner"** (no RunnerTests)

### 1.3 Cambiar Bundle Identifier

**Opción 1 - UI de Xcode (Recomendado):**

1. Con "Runner" seleccionado
2. Tab **"General"**
3. Sección **"Identity"**
4. Campo **"Bundle Identifier":**
   ```
   com.chamosfitness.app
   ```

**Opción 2 - Editar project.pbxproj (Avanzado):**

```bash
# En terminal
cd ios
nano Runner.xcodeproj/project.pbxproj

# Buscar (Ctrl+W):
com.chamosfitness.chamosFitnessCenterTemp

# Reemplazar por:
com.chamosfitness.app

# Guardar: Ctrl+O, Enter, Ctrl+X
```

### 1.4 Verificar Info.plist

```bash
# Abre Info.plist
open ios/Runner/Info.plist
```

Verifica que `CFBundleIdentifier` tenga:
```xml
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
```

**NO debe estar hardcodeado.** Debe usar la variable.

### 1.5 Guardar Cambios

En Xcode:
- **File** → **Save** (⌘S)
- O cerrar Xcode (guardará automáticamente)

---

## 🔐 Paso 2: Configurar Apple Developer Account

### 2.1 Acceder al Portal

1. Ve a [Apple Developer Portal](https://developer.apple.com/account)
2. Login con tu Apple ID (la cuenta que pagó los $99)
3. Verifica que veas el dashboard

### 2.2 Registrar App ID (Bundle Identifier)

**Navegación:**
```
Certificates, Identifiers & Profiles
→ Identifiers
→ + (botón azul arriba a la derecha)
```

**Configuración:**

1. **Selecciona tipo:**
   - ☑️ App IDs
   - Click **Continue**

2. **Selecciona tipo de App ID:**
   - ☑️ App (no App Clip)
   - Click **Continue**

3. **Configurar App ID:**
   ```
   Description: Chamos Fitness Center
   
   Bundle ID: 
   ☑️ Explicit (no Wildcard)
   com.chamosfitness.app
   ```

4. **Capabilities (selecciona las que uses):**
   ```
   ☑️ Associated Domains (para deep linking Supabase)
   ☑️ Push Notifications (si usas notificaciones)
   ☐ Sign in with Apple (si implementas)
   ☐ In-App Purchase (si vendes)
   ☐ Game Center (si es juego)
   ```

5. Click **Continue**
6. Revisa información
7. Click **Register**

✅ **App ID creado exitosamente**

### 2.3 Crear Certificados

#### A. Development Certificate (Para Testing)

1. **Certificates** → **+** (agregar)
2. Selecciona **"Apple Development"**
3. Click **Continue**

**Generar Certificate Signing Request (CSR):**

En tu Mac:
1. Abre **Keychain Access** (búscalo en Spotlight)
2. Menu: **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
3. Completa:
   ```
   User Email Address: tu-email@example.com
   Common Name: Tu Nombre
   CA Email Address: (déjalo vacío)
   Request is: ☑️ Saved to disk
   ```
4. Click **Continue**
5. Guarda como: `CertificateSigningRequest.certSigningRequest`
6. Click **Save**

**Subir CSR al Developer Portal:**

1. Click **Choose File**
2. Selecciona el archivo `.certSigningRequest` que acabas de crear
3. Click **Continue**
4. Click **Download** para descargar el certificado
5. **Doble click** en el archivo descargado (se instalará en Keychain)

#### B. Distribution Certificate (Para App Store)

**IMPORTANTE:** Este certificado es crítico para publicar.

1. **Certificates** → **+**
2. Selecciona **"Apple Distribution"**
3. Click **Continue**
4. Sube el **mismo CSR** que generaste antes
5. Click **Continue**
6. Click **Download**
7. **Doble click** para instalar

**🔐 BACKUP CRÍTICO:**

```bash
# En Keychain Access (en tu Mac):
1. Click en "login" (panel izquierdo)
2. Click en "Certificates" 
3. Busca "Apple Distribution: Tu Nombre (TEAM_ID)"
4. Click derecho → Export "Apple Distribution..."
5. Guardar como: chamos-distribution-cert.p12
6. Pon una contraseña FUERTE
7. Guarda el .p12 en 3 lugares seguros:
   - OneDrive/Google Drive (encriptado)
   - USB externo
   - Password manager (como adjunto)
```

⚠️ **Si pierdes este certificado, tendrás problemas serios.**

### 2.4 Crear Provisioning Profiles

#### A. Development Provisioning Profile

1. **Profiles** → **+**
2. **Development** → **iOS App Development**
3. Click **Continue**
4. Selecciona tu App ID: `com.chamosfitness.app`
5. Click **Continue**
6. Selecciona tu **Development Certificate**
7. Click **Continue**
8. Selecciona **dispositivos** para testing:
   - Marca tu iPhone/iPad personal
   - (Antes debes registrar dispositivos en Devices section)
9. Click **Continue**
10. Nombre: `Chamos Fitness Dev Profile`
11. Click **Generate**
12. Click **Download**
13. **Doble click** para instalar

#### B. App Store Distribution Profile

1. **Profiles** → **+**
2. **Distribution** → **App Store**
3. Click **Continue**
4. Selecciona tu App ID: `com.chamosfitness.app`
5. Click **Continue**
6. Selecciona tu **Distribution Certificate**
7. Click **Continue**
8. Nombre: `Chamos Fitness AppStore Profile`
9. Click **Generate**
10. Click **Download**
11. **Doble click** para instalar

✅ **Profiles instalados en Xcode automáticamente**

---

## 🔑 Paso 3: Configurar Signing en Xcode

### 3.1 Abrir Proyecto

```bash
cd /ruta/a/ChamosFitnessCenter
open ios/Runner.xcworkspace
```

### 3.2 Configurar Team y Signing

1. En Xcode, selecciona **"Runner"** (proyecto raíz)
2. Selecciona target **"Runner"**
3. Tab **"Signing & Capabilities"**

### 3.3 Debug Configuration

**Sección: Debug**

```
☐ Automatically manage signing (DESACTIVA ESTO)

Team: Selecciona tu equipo (Tu Nombre - TEAM_ID)

Provisioning Profile: 
Chamos Fitness Dev Profile (Development)

Signing Certificate:
Apple Development: Tu Nombre (TEAM_ID)
```

### 3.4 Release Configuration

**Sección: Release**

```
☐ Automatically manage signing (DESACTIVA ESTO)

Team: Selecciona tu equipo (Tu Nombre - TEAM_ID)

Provisioning Profile: 
Chamos Fitness AppStore Profile (App Store)

Signing Certificate:
Apple Distribution: Tu Nombre (TEAM_ID)
```

### 3.5 Verificar Bundle Identifier

En la misma pantalla, verifica:
```
Bundle Identifier: com.chamosfitness.app
```

✅ **Debe estar sin errores ni advertencias**

### 3.6 Capabilities (Opcional)

Si usas funciones especiales:

**Tab: Signing & Capabilities** → **+ Capability**

Agrega según necesites:
- **Associated Domains** (para deep links de Supabase)
  - Domains: `applinks:chamosfitness.com`
- **Push Notifications** (para notificaciones push)
- **Background Modes** (para tareas en background)

---

## 🏗️ Paso 4: Build IPA

### 4.1 Preparar el Proyecto

```bash
# En Mac Terminal, en la raíz del proyecto
cd /ruta/a/ChamosFitnessCenter

# Limpiar builds anteriores
flutter clean

# Instalar dependencias
flutter pub get

# Instalar pods de iOS
cd ios
pod install
cd ..
```

### 4.2 Verificar Versión

Edita `pubspec.yaml`:
```yaml
version: 1.0.0+1
# Formato: MAJOR.MINOR.PATCH+BUILD_NUMBER
# 1.0.0 = Version Name (visible para usuarios)
# 1 = Build Number (incrementa en cada build)
```

### 4.3 Build IPA con Flutter

```bash
# Método recomendado - Flutter CLI
flutter build ipa --release

# Si da error, usa verbose para ver detalles:
flutter build ipa --release --verbose
```

**Ubicación del IPA:**
```
build/ios/ipa/chamos_fitness_center.ipa
```

**Tamaño esperado:** 40-80 MB

### 4.4 Build desde Xcode (Alternativa)

Si el método anterior falla:

```bash
# Abre Xcode
open ios/Runner.xcworkspace
```

En Xcode:
1. **Product** → **Scheme** → **Runner**
2. **Product** → **Destination** → **Any iOS Device (arm64)**
3. **Product** → **Archive**
4. Espera a que compile (5-15 minutos)

Cuando termine:
- Abrirá **Organizer** automáticamente
- Verás tu archive listado

### 4.5 Verificar el Build

**Checklist:**
```bash
# Verifica que existe el IPA
ls -lh build/ios/ipa/chamos_fitness_center.ipa

# Debe mostrar:
# -rw-r--r--  1 user  staff    45M Feb 11 12:00 chamos_fitness_center.ipa
```

**En Xcode Organizer:**
- Sin errores de signing
- Version: 1.0.0
- Build: 1
- Ícono correcto visible

---

## 🎮 Paso 5: Crear App en App Store Connect

### 5.1 Acceder a App Store Connect

1. Ve a [App Store Connect](https://appstoreconnect.apple.com)
2. Login con tu Apple ID de Developer
3. Dashboard principal

### 5.2 Crear Nueva App

**Click:** "My Apps" → **+** (esquina superior izquierda) → **New App**

**Información básica:**

```
Platforms: ☑️ iOS

Name: Chamos Fitness Center
(Este es el nombre que verán los usuarios)

Primary Language: Spanish (Spain) - es-ES
(O Spanish (Mexico) - es-MX si prefieres)

Bundle ID: 
com.chamosfitness.app (selecciona de la lista)
(Debe aparecer automáticamente si registraste el App ID)

SKU: CHAMOS-FITNESS-001
(Identificador interno único, no visible para usuarios)
(Solo números, letras, guiones, puntos)

User Access: Full Access
(O Limited si trabajas en equipo)
```

**Click:** "Create"

### 5.3 Dashboard de la App

Verás el panel de control con secciones:
```
□ App Information
□ Pricing and Availability  
□ Prepare for Submission
□ App Privacy
□ Version 1.0.0
```

---

## 📸 Paso 6: Preparar Assets

### 6.1 App Icon

**Especificaciones:**
- **Tamaño:** 1024 × 1024 pixels
- **Formato:** PNG (sin transparencia/alpha channel)
- **Sin esquinas redondeadas** (iOS lo hace automáticamente)
- **Sin texto del nombre de la app**

**Herramientas:**
- [Canva](https://canva.com) - Gratis
- [Figma](https://figma.com) - Gratis
- Adobe Illustrator
- [App Icon Generator](https://appicon.co/)

**Diseño recomendado para Chamos:**
- Fondo: Negro (#0a0a0a) o Dorado (#FFD700)
- Ícono: Pesas 🏋️ o logo de Chamos
- Estilo: Flat, minimalista, reconocible

### 6.2 Screenshots (Capturas de Pantalla)

**OBLIGATORIO - iPhone 6.7":**
- **Tamaño:** 1290 × 2796 pixels
- **Dispositivos:** iPhone 15 Pro Max, 14 Pro Max
- **Orientación:** Portrait (vertical)
- **Cantidad:** Mínimo 3, máximo 10

**OBLIGATORIO - iPhone 6.5":**
- **Tamaño:** 1284 × 2778 pixels
- **Dispositivos:** iPhone 14 Plus, 13 Pro Max, 12 Pro Max
- **Orientación:** Portrait
- **Cantidad:** Mínimo 3, máximo 10

**OPCIONAL - iPad Pro 12.9":**
- **Tamaño:** 2048 × 2732 pixels (portrait)
- **Cantidad:** Mínimo 3, máximo 10

**Orden sugerido de screenshots:**
```
1. Pantalla principal / Dashboard (más impresionante primero)
2. Lista de rutinas de entrenamiento
3. Ejercicio en acción con video
4. Estadísticas y progreso con gráficos
5. Perfil de usuario con logros
6. Planes de nutrición
```

### 6.3 Cómo Capturar Screenshots

**Método 1 - Flutter en Simulador:**

```bash
# En Mac Terminal
# Abre simulador de iPhone 15 Pro Max
open -a Simulator

# En Simulator: Device → iPhone 15 Pro Max

# Corre la app
flutter run

# Para capturar: Cmd + S (se guarda en Desktop)
```

**Método 2 - Xcode Simulator:**

1. Xcode → Open Developer Tool → Simulator
2. Device → iPhone 15 Pro Max
3. Navega por la app
4. **Cmd + S** para capturar

**Ubicación:** `~/Desktop/` (nombre: Screenshot YYYY-MM-DD at HH.MM.SS.png)

### 6.4 Editar Screenshots (Opcional)

**Agregar marcos de dispositivo:**
- [Shots.so](https://shots.so/) - Gratis online
- [Previewed](https://previewed.app/) - Mockups profesionales
- [Device Art Generator](https://deviceart.app/)

**Agregar texto descriptivo:**
- Título de la feature
- Breve descripción (1 línea)
- Mantén branding consistente

**Dimensiones finales deben coincidir exactamente:**
- 1290 × 2796 (iPhone 6.7")
- 1284 × 2778 (iPhone 6.5")

---

## 📝 Paso 7: Configurar Metadata

En App Store Connect → Tu app → **Version 1.0.0**

### 7.1 App Information

**Click:** "App Information" (menú izquierdo)

```
Name: Chamos Fitness Center
(Máximo 30 caracteres)

Subtitle: Tu entrenamiento personalizado
(Máximo 30 caracteres, aparece bajo el nombre)

Primary Category: Health & Fitness

Secondary Category (opcional): Lifestyle

Content Rights: 
☑️ Contains Third-Party Content
(Si usas videos de YouTube, música, etc.)
```

### 7.2 Pricing and Availability

**Click:** "Pricing and Availability"

```
Price Schedule:
☑️ Free (Gratis)
o
Selecciona tier de precio si es de pago

Availability:
☑️ All countries and regions
o
Selecciona países específicos

Pre-Order:
☐ Make this app available for pre-order
(Déjalo desmarcado para primera versión)
```

### 7.3 Version Information

**Click:** "1.0.0" (en versiones)

**Screenshots y Videos:**
- Arrastra tus screenshots a cada tamaño de pantalla
- Orden: Más impactante primero
- Verifica que se vean bien en preview

**Promotional Text (170 caracteres):**
```
🏋️ Transforma tu cuerpo con rutinas personalizadas, 
seguimiento de progreso y planes de nutrición. 
¡Comienza hoy tu mejor versión!
```

**Description (4000 caracteres máx):**
```
💪 CHAMOS FITNESS CENTER - TU GYM EN EL BOLSILLO

Lleva tu entrenamiento al siguiente nivel con la app oficial 
de Chamos Fitness Center. Diseñada por entrenadores 
profesionales para ofrecerte la mejor experiencia de fitness.

🎯 CARACTERÍSTICAS PRINCIPALES:

✓ RUTINAS PERSONALIZADAS
• Planes adaptados a tu nivel: Principiante, Intermedio, Avanzado
• Ejercicios con videos demostrativos profesionales
• Seguimiento detallado de series, repeticiones y descanso
• Especialidades: Fuerza, Volumen y Resistencia

✓ SEGUIMIENTO DE PROGRESO
• Historial completo de entrenamientos
• Estadísticas y gráficos de rendimiento  
• Medidas corporales y evolución de peso
• Calorías quemadas por sesión

✓ PLANES DE NUTRICIÓN
• Recetas saludables personalizadas
• Calculadora de calorías y macronutrientes
• Planes de alimentación semanales
• Instrucciones paso a paso

✓ BIBLIOTECA DE EJERCICIOS
• Más de 100 ejercicios documentados
• Videos HD de cada movimiento
• Instrucciones detalladas
• Filtrado por grupo muscular

✓ MOTIVACIÓN Y COMUNIDAD
• Sistema de logros y badges
• Comparte tu progreso
• Recordatorios personalizados
• Metas alcanzables

📊 RESULTADOS COMPROBADOS
Únete a miles de usuarios que han transformado su cuerpo 
con Chamos Fitness Center. Ya sea que busques ganar músculo, 
perder peso o mejorar resistencia, tenemos el plan perfecto.

🔒 PRIVACIDAD GARANTIZADA
Tus datos están protegidos con encriptación de nivel bancario. 
Cumplimos con todas las normativas de privacidad.

💎 100% GRATIS
Sin suscripciones ocultas ni pagos sorpresa.

📱 COMPATIBILIDAD
Requiere iOS 12.0 o superior. Optimizada para iPhone y iPad.

---
SOPORTE
📧 support@chamosfitness.com
🌐 https://chamosfitness.com

LEGAL
Términos: https://chamosfitness.com/terms
Privacidad: https://chamosfitness.com/privacy

© 2026 Chamos Fitness Center
```

**Keywords (100 caracteres máx, separados por comas):**
```
fitness,gym,entrenamiento,rutinas,ejercicio,salud,músculo,nutrición,peso,deporte
```

**Support URL (obligatorio):**
```
https://chamosfitness.com/support
```

**Marketing URL (opcional):**
```
https://chamosfitness.com
```

**Version (What's New) - 4000 caracteres:**
```
🎉 PRIMERA VERSIÓN DE CHAMOS FITNESS CENTER

Bienvenido a tu nuevo compañero de entrenamiento. 
Esta versión inicial incluye:

✨ FUNCIONALIDADES
• Rutinas personalizadas para todos los niveles
• Biblioteca completa de ejercicios con videos
• Seguimiento detallado de progreso
• Planes de nutrición y recetas
• Historial de entrenamientos
• Medidas corporales
• Sistema de logros

💪 ¡Comienza tu transformación hoy!

Para soporte: support@chamosfitness.com
```

**Copyright:**
```
2026 Chamos Fitness Center
```

**Click:** "Save"

---

## 🔒 Paso 8: App Privacy

Apple requiere declaración detallada de privacidad.

**Click:** "App Privacy" (menú izquierdo) → **Get Started**

### 8.1 Data Collection

**¿Recopilas datos de usuarios?**
```
☑️ Yes
```

### 8.2 Data Types

**Contact Info:**
```
☑️ Email Address

How is this data used?
☑️ App Functionality (crear cuenta, login)
☑️ Developer's Advertising or Marketing

Is this data linked to the user?
☑️ Yes

Do you track this data for tracking purposes?
☐ No
```

**Health & Fitness:**
```
☑️ Fitness

What fitness data?
☑️ Workout data
☑️ Exercise data

How is this data used?
☑️ App Functionality

Is this data linked to the user?
☑️ Yes

Do you track?
☐ No
```

```
☑️ Other Health Data

What health data?
Body measurements (peso, medidas corporales)

How is this data used?
☑️ App Functionality
☑️ Analytics

Is this data linked to the user?
☑️ Yes

Do you track?
☐ No
```

**User Content:**
```
☑️ Photos or Videos

How is this data used?
☑️ App Functionality (foto de perfil, progreso)

Is this data linked to the user?
☑️ Yes

Do you track?
☐ No
```

**Identifiers:**
```
☑️ User ID

How is this data used?
☑️ App Functionality (identificar usuario)
☑️ Analytics

Is this data linked to the user?
☑️ Yes

Do you track?
☐ No
```

**Usage Data:**
```
☑️ Product Interaction

How is this data used?
☑️ Analytics (mejorar app)
☑️ Product Personalization

Is this data linked to the user?
☑️ Yes

Do you track?
☐ No
```

### 8.3 Privacy Policy URL

```
Privacy Policy URL: https://chamosfitness.com/privacy-policy
```

⚠️ **CRÍTICO:** Esta URL debe:
- Estar publicada y accesible públicamente
- Funcionar sin errores 404
- Contenido real (no página vacía)
- Explicar qué datos recopilas y cómo los usas

**Click:** "Publish"

---

## 📤 Paso 9: Subir Build

### 9.1 Usando Xcode Organizer (Recomendado)

1. En Mac, abre Xcode
2. **Window** → **Organizer** (o Shift+Cmd+9)
3. Verás tu archive de antes
4. Selecciona el archive más reciente
5. Click **"Distribute App"**

**Opciones:**
```
Método de distribución:
☑️ App Store Connect

Options:
☑️ Upload your app's symbols (debugging)
☑️ Manage Version and Build Number automatically
☐ Strip Swift symbols (dejar desmarcado)
```

6. Click **"Next"**
7. Selecciona **Provisioning Profile:**
   - Automatically manage signing ✅ (recomendado)
8. Click **"Upload"**
9. Espera (5-15 minutos dependiendo de internet)

**Confirmación:**
```
✅ Upload Successful

Your app has been uploaded to App Store Connect.
Check your email for status updates.
```

### 9.2 Usando Transporter App (Alternativa)

Si Organizer da problemas:

1. Descarga [Transporter](https://apps.apple.com/app/transporter/id1450874784) desde App Store
2. Login con tu Apple ID
3. Arrastra tu `.ipa` a la ventana
4. Click **"Deliver"**
5. Espera confirmación

### 9.3 Verificar Procesamiento

1. Ve a [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → Chamos Fitness Center
3. **Activity** tab
4. Verás el build en proceso

**Estados:**
```
Processing... (10-30 minutos)
↓
Ready to Submit
```

**Recibirás emails:**
- Confirming upload
- Processing complete
- Ready for testing

---

## 🧪 Paso 10: TestFlight (Beta Testing)

### 10.1 ¿Qué es TestFlight?

- App oficial de Apple para beta testing
- Prueba tu app antes de publicarla
- Hasta 10,000 testers externos
- 100 dispositivos internos

### 10.2 Internal Testing

**En App Store Connect:**

1. **TestFlight** tab
2. Sección **"Internal Testing"**
3. Click **"+"** para crear grupo
4. Nombre: "Team Chamos"
5. **Add Build:** Selecciona el build que subiste
6. **Add Testers:** 
   - Click **"+"**
   - Agrega emails de tu equipo
   - Máximo: 100 personas

**Invitaciones automáticas:**
- Testers reciben email
- Descargan TestFlight app
- Aceptan invitación
- Instalan la app beta

**Sin revisión de Apple (instantáneo)**

### 10.3 External Testing

Para más testers o usuarios externos:

1. **TestFlight** → **"External Testing"**
2. Click **"+"** crear grupo
3. Nombre: "Beta Testers Públicos"
4. **Add Build**
5. Completa beta information:
   ```
   What to Test:
   Buscamos feedback en:
   - Facilidad de uso
   - Bugs o crashes
   - Rendimiento
   - Sugerencias de mejora
   
   Feedback Email: beta@chamosfitness.com
   ```
6. **Submit for Beta App Review**
7. Espera aprobación (1-2 días)

**Una vez aprobado:**
- Comparte link público
- Hasta 10,000 testers
- Expira en 90 días

### 10.4 Recopilar Feedback

**TestFlight incluye:**
- Crash reports automáticos
- Screenshots de testers
- Comentarios directos
- Métricas de uso

**Acceder feedback:**
```
TestFlight tab → Builds → Selecciona build → Crashes & Feedback
```

**Actuar sobre feedback:**
1. Fix bugs críticos
2. Considera sugerencias
3. Sube nuevo build (incrementa build number)
4. Vuelve a testear

---

## ✅ Paso 11: Submit for Review

### 11.1 Checklist Pre-Review

Verifica TODO antes de enviar:

```
✅ Build procesado en App Store Connect
✅ Screenshots subidos (mínimo 3 por tamaño)
✅ App Icon 1024x1024
✅ Descripción completa
✅ Keywords
✅ URLs de soporte y privacidad funcionando
✅ App Privacy completado
✅ Export Compliance respondido
✅ Version Information completa
✅ Tested en TestFlight sin crashes
```

### 11.2 Seleccionar Build

1. Ve a **"1.0.0"** en versiones
2. **Build** section
3. Click **"+"** o "Select a Build"
4. Selecciona el build de TestFlight
5. **Done**

### 11.3 Export Compliance

Si aparece advertencia "Missing Compliance":

**¿Tu app usa encriptación?**

Para Chamos Fitness (usando HTTPS solamente):
```
☑️ No

Razón: Solo usa HTTPS estándar del sistema operativo, 
no implementa encriptación adicional.
```

Si usas encriptación personalizada:
```
☑️ Yes
→ Completa cuestionario detallado
```

### 11.4 Content Rights

**¿Contiene contenido de terceros?**

Si usas videos de YouTube, imágenes de stock:
```
☑️ Yes

Do you have all necessary rights?
☑️ Yes
```

### 11.5 Advertising Identifier (IDFA)

**¿Sirves anuncios?**
```
Para Chamos Fitness:
☐ No (si no hay ads)
```

Si tienes ads:
```
☑️ Yes
→ Selecciona propósitos del tracking
```

### 11.6 Version Release

**¿Cómo quieres lanzar?**

```
☑️ Automatically release this version
(Se publica automáticamente al ser aprobada)

o

☐ Manually release this version
(Tú decides cuándo publicar después de aprobación)

o

☐ Scheduled for: [fecha]
(Se publica en fecha específica)
```

**Recomendación primera versión:** Manual release

### 11.7 Phased Release (Opcional)

```
☑️ Release this version over a 7-day period using phased release

Beneficios:
- Día 1: 1% usuarios
- Día 2: 2% usuarios  
- Día 3: 5% usuarios
- Día 4: 10% usuarios
- Día 5: 20% usuarios
- Día 6: 50% usuarios
- Día 7: 100% usuarios

Puedes pausar si detectas problemas críticos.
```

### 11.8 Submit

**Click:** "Add for Review"

Revisa toda la información final:
```
App name: Chamos Fitness Center
Version: 1.0.0
Build: 1
Primary Language: Spanish
Category: Health & Fitness
Price: Free
```

**Click:** "Submit to App Review"

**Confirmación:**
```
🎉 Your app has been submitted for review

Team Chamos will receive notifications when 
the status changes.
```

---

## ⏱️ Proceso de Revisión

### Tiempos Típicos

| Estado | Tiempo Estimado |
|--------|----------------|
| Waiting for Review | 12-48 horas |
| In Review | 24-48 horas |
| Total (primera app) | 48-72 horas |
| Updates subsecuentes | 12-24 horas |

### Estados Posibles

**1. Waiting for Review**
```
🟡 Tu app está en cola esperando revisión
```

**2. In Review**
```
🔵 Un revisor de Apple está evaluando tu app
```

**3. Pending Developer Release**
```
🟢 ¡Aprobada! Esperando que publiques manualmente
(Si elegiste manual release)
```

**4. Ready for Sale**
```
🎉 ¡Publicada en App Store!
```

**5. Rejected**
```
🔴 App rechazada - requiere cambios
```

### Motivos Comunes de Rechazo

1. **Screenshots no coinciden con la app**
   - Solución: Actualiza screenshots con contenido real

2. **Privacy Policy incompleta o no accesible**
   - Solución: Fix URL, agrega contenido real

3. **Crashes al revisar**
   - Solución: Fix bugs, testea más con TestFlight

4. **Funcionalidad no clara**
   - Solución: Mejora descripción, agrega demo account

5. **Violación de guidelines**
   - Solución: Lee feedback, ajusta según indicaciones

### Responder a Rechazo

Si te rechazan:

1. **Lee el mensaje completo** en Resolution Center
2. Fix los problemas indicados
3. Responde en Resolution Center explicando cambios
4. **Submit nuevamente** (no necesitas nuevo build si el problema es de metadata)

---

## 📊 Paso 12: Post-Launch

### 12.1 ¡Aprobación!

Recibirás email:
```
✅ Your app "Chamos Fitness Center" is now Ready for Sale

Your app is now available on the App Store
```

**Link de tu app:**
```
https://apps.apple.com/app/chamos-fitness-center/[APP_ID]
```

### 12.2 Primeras 24 Horas

**Monitorea:**

1. **App Analytics:**
   - App Store Connect → Analytics → Metrics
   - Impresiones
   - Descargas
   - Conversion rate

2. **Crashes:**
   - Xcode → Organizer → Crashes
   - Debe ser < 1%

3. **Reviews:**
   - App Store Connect → Ratings and Reviews
   - **Responde TODOS los reviews**

### 12.3 Responder Reviews

**Review positivo (5 estrellas):**
```
¡Muchas gracias por tu apoyo! 💪 Nos alegra que 
estés disfrutando de Chamos Fitness. ¡Sigue 
entrenando fuerte!

- Equipo Chamos
```

**Review negativo (1-2 estrellas):**
```
Lamentamos tu experiencia. Nos encantaría ayudarte 
a resolver el problema. Por favor contáctanos en 
support@chamosfitness.com con más detalles.

Trabajamos constantemente en mejorar la app.

- Equipo Chamos
```

**Review con bug reportado:**
```
Gracias por reportar este problema. Ya estamos 
trabajando en una solución que estará disponible 
en la próxima actualización.

Mientras tanto, puedes [workaround si aplica].

- Equipo Chamos
```

### 12.4 Pedir Reviews a Usuarios

**iOS nativo (recomendado):**

```dart
// En Flutter, usa package
import 'package:in_app_review/in_app_review.dart';

final InAppReview inAppReview = InAppReview.instance;

// Solo pedir después de experiencia positiva
if (await inAppReview.isAvailable()) {
  inAppReview.requestReview();
}
```

**Cuándo pedir:**
- ✅ Después de completar 5 entrenamientos
- ✅ Al alcanzar un logro importante
- ✅ Después de usar la app 1 semana
- ❌ NO en primer uso
- ❌ NO más de 3 veces al año por usuario

### 12.5 Promoción

**Share en redes sociales:**
```
🎉 ¡Chamos Fitness Center ya está en App Store! 🏋️

Transforma tu cuerpo con rutinas personalizadas, 
seguimiento de progreso y planes de nutrición.

📱 Descarga gratis: [link]

#ChamosFitness #Fitness #Gym #AppStore
```

**Email a base de usuarios (si tienes):**
```
Asunto: 🎉 ¡Ya estamos en App Store!

Hola [nombre],

Nos complace anunciar que Chamos Fitness Center 
está oficialmente en App Store.

[Descripción breve]

Descarga ahora: [link]

¡Gracias por tu apoyo!
```

---

## 🔄 Hacer Updates

### Proceso de Update

1. **Incrementa versión en `pubspec.yaml`:**
   ```yaml
   # Bug fixes
   version: 1.0.1+2
   
   # Nuevas features
   version: 1.1.0+3
   
   # Major changes
   version: 2.0.0+4
   ```

2. **Build nuevo IPA:**
   ```bash
   flutter clean
   flutter build ipa --release
   ```

3. **Sube a App Store Connect:**
   - Xcode → Organizer → Distribute
   - O Transporter app

4. **En App Store Connect:**
   - **+** para crear nueva versión
   - Agrega "What's New" notes
   - Selecciona nuevo build
   - Submit for review

5. **Espera aprobación** (12-24 horas típicamente)

### Release Notes Efectivas

**Ejemplo 1.0.1 (Bug fixes):**
```
Mejoras y correcciones:
• Solucionado crash al cargar rutinas
• Mejorada velocidad de sincronización
• Corrección en cálculo de calorías
• Mejoras menores de rendimiento

¡Gracias por tu feedback!
```

**Ejemplo 1.1.0 (Nuevas features):**
```
Novedades:
✨ Modo oscuro completo
✨ Exportar progreso a PDF
✨ Nuevas rutinas de yoga

Mejoras:
• Interfaz más intuitiva
• Carga más rápida

Correcciones:
• Varios bugs menores
```

---

## 🚨 Troubleshooting

### Error: "No provisioning profiles found"

```bash
Solución:
1. Xcode → Preferences → Accounts
2. Selecciona tu Apple ID
3. Click "Download Manual Profiles"
4. Reinicia Xcode
```

### Error: "Code signing failed"

```bash
Solución:
1. Verifica que Bundle ID coincida en Xcode y Developer Portal
2. Revisa que certificados estén instalados en Keychain
3. Product → Clean Build Folder
4. Intenta de nuevo
```

### Build procesando por más de 1 hora

```bash
Solución:
1. Espera 2 horas totales
2. Si sigue en Processing, contacta Apple Support
3. Revisa email por notificaciones de error
```

### "Missing Compliance" en TestFlight

```bash
Solución:
1. App Store Connect → TestFlight → Build
2. Click en advertencia amarilla
3. Responde cuestionario de encriptación
4. Submit
```

### App rechazada por "Guideline 2.1 - Performance"

```bash
Motivo: App crash durante review

Solución:
1. Testea extensivamente en TestFlight
2. Fix todos los crashes conocidos
3. Agrega mejor manejo de errores
4. Reenvía con explicación de fixes
```

---

## 💡 Tips para Éxito

### ✅ DO:

1. **Testea MUCHO en TestFlight** antes de submit
2. **Responde todos los reviews** dentro de 48 horas
3. **Actualiza regularmente** (cada 2-4 semanas)
4. **Usa screenshots reales** de tu app
5. **Privacy Policy clara** y accesible
6. **Keywords relevantes** sin spam
7. **Description convincente** pero honesta
8. **Request reviews inteligentemente** (no en cada uso)

### ❌ DON'T:

1. **No copies a otras apps** en screenshots/descripción
2. **No prometas features** que no tienes
3. **No uses keywords irrelevantes** (keyword stuffing)
4. **No plagies íconos** de otras apps
5. **No ignores crashes** (fix ASAP)
6. **No subas sin testear** en dispositivos reales
7. **No mientas** en App Privacy
8. **No uses screenshots genéricos** de stock

---

## 📈 ASO (App Store Optimization)

### Título Optimizado

```
Chamos Fitness Center
(Máximo 30 caracteres)

Si tienes espacio:
Chamos Fitness - Entrenamiento
```

### Subtitle Efectivo

```
Tu entrenamiento personalizado
(Máximo 30 caracteres)

O:
Rutinas de gym personalizadas
```

### Keywords Estratégicos

```
fitness,gym,entrenamiento,rutinas,ejercicio,músculo,
nutrición,salud,peso,deporte

Total: 100 caracteres
```

**Tips:**
- No repitas palabras del título
- No uses espacios después de comas
- Singular y plural (algoritmo lo detecta)
- Usa sinónimos relevantes

### Screenshots Optimizados

**Primero = Más importante:**
- Dashboard con estadísticas impresionantes
- Muestra la propuesta de valor CLARA

**Incluye texto en screenshots:**
- Grande, legible
- Alto contraste
- Feature destacada
- Máximo 3-5 palabras por screenshot

---

## 📞 Recursos y Soporte

### Documentación Oficial:

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)

### Contacto Apple:

- Developer Support: https://developer.apple.com/support/
- Phone: 1-800-MY-APPLE (EE.UU.)
- Email: developer-support@apple.com

### Comunidades:

- [Apple Developer Forums](https://developer.apple.com/forums/)
- [Stack Overflow - iOS](https://stackoverflow.com/questions/tagged/ios)
- [Reddit - r/iOSProgramming](https://reddit.com/r/iOSProgramming)
- Flutter Discord

### Herramientas Útiles:

- [App Store Optimization Stack](https://appradar.com/)
- [Sensor Tower](https://sensortower.com/) - ASO & Analytics
- [App Annie](https://www.appannie.com/) - Market intelligence
- [TestFlight](https://developer.apple.com/testflight/) - Beta testing

---

## ✅ Checklist Final Completo

### Pre-Build:
- [ ] Mac con macOS 12.0+ disponible
- [ ] Xcode 14.0+ instalado
- [ ] Apple Developer Account activa ($99 pagados)
- [ ] CocoaPods instalado
- [ ] Bundle ID actualizado a producción
- [ ] Info.plist con permisos y descripciones

### Certificates & Profiles:
- [ ] App ID registrado en Developer Portal
- [ ] Development Certificate instalado
- [ ] Distribution Certificate instalado y respaldado
- [ ] Development Provisioning Profile
- [ ] App Store Distribution Profile
- [ ] Signing configurado en Xcode (Manual)

### Build:
- [ ] `flutter clean` ejecutado
- [ ] Pods instalados (`pod install`)
- [ ] Versión correcta en pubspec.yaml (1.0.0+1)
- [ ] `flutter build ipa --release` exitoso
- [ ] IPA generado sin errores
- [ ] Tested en dispositivo físico

### App Store Connect:
- [ ] App creada en App Store Connect
- [ ] Build subido y procesado
- [ ] Screenshots (3+ por tamaño requerido)
- [ ] App icon 1024×1024
- [ ] Descripción completa y keywords
- [ ] Privacy Policy URL funcionando
- [ ] Terms URL funcionando
- [ ] Support URL funcionando
- [ ] App Privacy completado
- [ ] Export Compliance respondido
- [ ] Pricing configurado (Free/Paid)
- [ ] Países seleccionados

### Testing:
- [ ] TestFlight internal testing
- [ ] Beta feedback recopilado
- [ ] Crashes corregidos
- [ ] Funcionalidad completa verificada
- [ ] Tested en iPhone y iPad
- [ ] Sin bugs críticos conocidos

### Legal:
- [ ] Privacy Policy publicada y accesible
- [ ] Terms & Conditions publicados
- [ ] Copyright correcto (2026)
- [ ] Email de soporte configurado

### Pre-Submit:
- [ ] Build seleccionado en versión 1.0.0
- [ ] Version Release configurado
- [ ] Phased Release decidido
- [ ] Screenshots finales verificados
- [ ] Descripción revisada
- [ ] Todo checklist en verde

---

## 🎉 ¡Felicidades!

**Tu app está lista para App Store! 🚀**

**Próximos pasos:**
1. Submit for review
2. Esperar aprobación (24-72 horas)
3. Publicar
4. Promocionar
5. Responder reviews
6. Planear updates

**Link de tu app:**
```
https://apps.apple.com/app/chamos-fitness-center/[ID]
```

**¡Éxito con el lanzamiento! 💪**

---

**Última actualización:** 11 de febrero de 2026  
**Mantenido por:** Equipo Chamos Fitness Center  
**Próxima revisión:** Después de primera publicación  
**Versión del documento:** 1.0.0