# 🤖 GUÍA DE PUBLICACIÓN EN GOOGLE PLAY STORE
## Chamos Fitness Center - Android

**Última actualización:** 11 de febrero de 2026  
**Versión:** 1.0.0  
**Estado:** ✅ Listo para configurar signing keys

---

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Generar Signing Key](#paso-1-generar-signing-key)
3. [Configurar Signing](#paso-2-configurar-signing)
4. [Build APK/AAB](#paso-3-build-apkaab)
5. [Crear App en Play Console](#paso-4-crear-app-en-play-console)
6. [Preparar Assets](#paso-5-preparar-assets)
7. [Configurar Store Listing](#paso-6-configurar-store-listing)
8. [Clasificación de Contenido](#paso-7-clasificación-de-contenido)
9. [Información de Privacidad](#paso-8-información-de-privacidad)
10. [Subir AAB](#paso-9-subir-aab)
11. [Testing](#paso-10-testing)
12. [Publicar](#paso-11-publicar)
13. [Post-Launch](#paso-12-post-launch)

---

## ⚙️ Requisitos Previos

### ✅ Software Necesario

**Windows, Mac o Linux:**
- Flutter SDK instalado ✅ (ya lo tienes)
- Android Studio o Android SDK
- JDK 8 o superior
- Cuenta de Google Play Developer ($25 USD pago único)

### ✅ Verificar Instalación

```bash
# Verifica Flutter
flutter doctor

# Debe mostrar:
# [✓] Flutter (Channel stable, versión X.X.X)
# [✓] Android toolchain - develop for Android devices
```

### 💳 Cuenta de Google Play Developer

1. Ve a [Google Play Console](https://play.google.com/console/signup)
2. Pago único de **$25 USD**
3. Completa verificación de identidad
4. Acepta términos y condiciones

⏱️ **Tiempo de activación:** 24-48 horas después del pago

---

## 🔑 Paso 1: Generar Signing Key

### ¿Por qué es importante?

La **signing key** es como tu firma digital. Es **CRÍTICA** porque:
- Sin ella, NO puedes actualizar tu app NUNCA
- Google Play verifica que los updates vengan del mismo desarrollador
- Una vez publicada, estás atado a esa key para siempre

⚠️ **ADVERTENCIA:** Guarda backups en múltiples lugares seguros.

### 1.1 Verificar Java (keytool)

```bash
# En PowerShell o CMD
keytool -version

# Debe mostrar algo como:
# keytool version "1.8.0_XXX"
```

Si no funciona, instala JDK:
```bash
# Descarga desde:
# https://www.oracle.com/java/technologies/downloads/
# O usa OpenJDK
```

### 1.2 Generar el Keystore

```bash
# Navega a la carpeta android del proyecto
cd D:\ChamosFitnessCenter\android

# Genera el keystore
keytool -genkey -v -keystore chamos-release-key.jks ^
  -keyalg RSA -keysize 2048 -validity 10000 ^
  -alias chamos-key-alias
```

**⚠️ IMPORTANTE:** En el comando de arriba, el símbolo `^` es para Windows CMD. Si usas PowerShell, usa `` ` `` (backtick):

```powershell
# PowerShell version
keytool -genkey -v -keystore chamos-release-key.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias chamos-key-alias
```

### 1.3 Responder las Preguntas

El comando te pedirá información:

```
Enter keystore password: ********
  Re-enter new password: ********
  
What is your first and last name?
  [Unknown]: Juan Pérez (o tu nombre)
  
What is the name of your organizational unit?
  [Unknown]: Desarrollo (o dejalo en blanco)
  
What is the name of your organization?
  [Unknown]: Chamos Fitness Center
  
What is the name of your City or Locality?
  [Unknown]: Caracas (tu ciudad)
  
What is the name of your State or Province?
  [Unknown]: Miranda (tu estado)
  
What is the two-letter country code for this unit?
  [Unknown]: VE (código de tu país)
  
Is CN=Juan Pérez, OU=Desarrollo, O=Chamos Fitness Center, 
L=Caracas, ST=Miranda, C=VE correct?
  [no]: yes

Enter key password for <chamos-key-alias>
  (RETURN if same as keystore password): ******** (o presiona ENTER)
  Re-enter new password: ********
```

### 1.4 Verificar Generación

```bash
# Verifica que el archivo existe
dir chamos-release-key.jks

# Debe mostrar:
# chamos-release-key.jks
```

### 1.5 Guardar Contraseñas de Forma Segura

**🔐 CRÍTICO - Guarda estas contraseñas:**

1. **storePassword:** La contraseña del keystore
2. **keyPassword:** La contraseña de la key (si es diferente)
3. **keyAlias:** `chamos-key-alias`
4. **storeFile:** Ruta al archivo `.jks`

**Opciones seguras para guardar:**
- Password manager (1Password, LastPass, Bitwarden)
- Documento encriptado en cloud (Google Drive, OneDrive)
- Vault físico (caja fuerte)

⚠️ **NUNCA:**
- No las pongas en un archivo de texto sin encriptar
- No las subas a git/GitHub
- No las compartas por email/WhatsApp
- No las dejes en post-its

### 1.6 Hacer Backup del .jks

```bash
# Copia el archivo a múltiples ubicaciones:

# OneDrive/Google Drive
copy chamos-release-key.jks "C:\Users\TuUsuario\OneDrive\Backups\ChamosFitness\"

# USB/Disco externo
copy chamos-release-key.jks "E:\Backups\ChamosFitness\"

# Email a ti mismo (archivo encriptado en zip con contraseña)
# Usa 7-Zip o WinRAR para encriptar con contraseña fuerte
```

**🔄 Regla:** Mínimo **3 backups** en ubicaciones diferentes.

---

## 🔧 Paso 2: Configurar Signing

### 2.1 Crear key.properties

En la carpeta `android/`, crea el archivo `key.properties`:

```bash
# Copia el ejemplo
copy key.properties.example key.properties

# Edita con tu editor favorito
notepad key.properties
```

### 2.2 Completar key.properties

```properties
# Ruta ABSOLUTA al archivo .jks
# IMPORTANTE: Usa barras normales / o dobles \\
storeFile=D:/ChamosFitnessCenter/android/chamos-release-key.jks

# Contraseña del keystore (la que pusiste en el paso 1.3)
storePassword=TU_CONTRASEÑA_AQUI

# Alias de la key (debe ser: chamos-key-alias)
keyAlias=chamos-key-alias

# Contraseña de la key (si pusiste diferente, sino la misma)
keyPassword=TU_CONTRASEÑA_AQUI
```

**Ejemplo real:**
```properties
storeFile=D:/ChamosFitnessCenter/android/chamos-release-key.jks
storePassword=MiContraseñaSegura123!
keyAlias=chamos-key-alias
keyPassword=MiContraseñaSegura123!
```

⚠️ **IMPORTANTE:** 
- No uses espacios en las contraseñas (pueden causar problemas)
- Verifica que la ruta al .jks sea correcta
- Usa `/` en lugar de `\` en la ruta (incluso en Windows)

### 2.3 Verificar .gitignore

```bash
# Verifica que key.properties NO se suba a git
type .gitignore | findstr "key.properties"

# Debe mostrar:
# key.properties
```

✅ **Ya está configurado en tu proyecto** (lo hicimos antes)

---

## 🏗️ Paso 3: Build APK/AAB

### Diferencia entre APK y AAB

| Formato | Uso | Tamaño | Play Store |
|---------|-----|--------|------------|
| **APK** | Testing manual | ~50MB | ❌ No recomendado |
| **AAB** | Play Store | ~30MB optimizado | ✅ Obligatorio |

Google Play requiere **AAB** (Android App Bundle) desde agosto 2021.

### 3.1 Limpiar Build Anterior

```bash
# En la raíz del proyecto
flutter clean
flutter pub get
```

### 3.2 Build APK (Para Testing)

```bash
# Build APK de release
flutter build apk --release

# El APK estará en:
# build\app\outputs\flutter-apk\app-release.apk

# Tamaño aproximado: 40-60 MB
```

**Usar APK para:**
- Probar en tu dispositivo físico
- Compartir con beta testers (sin Play Store)
- Verificar que funciona correctamente

**Instalar APK en dispositivo:**
```bash
# Conecta tu Android por USB con Debug habilitado
flutter install
```

### 3.3 Build AAB (Para Play Store) ⭐

```bash
# Build AAB de release
flutter build appbundle --release

# El AAB estará en:
# build\app\outputs\bundle\release\app-release.aab

# Tamaño aproximado: 30-40 MB
```

### 3.4 Verificar el Build

**Checklist de verificación:**
```bash
# 1. Sin errores en el build
# Verifica que no haya mensajes de error

# 2. Tamaño razonable
dir build\app\outputs\bundle\release\app-release.aab
# Debe ser < 100 MB

# 3. Fecha actual
# Verifica que sea del día de hoy

# 4. Versión correcta
# En pubspec.yaml debe ser: version: 1.0.0+1
```

### 3.5 Build con Verbose (Si hay errores)

```bash
# Ver detalles del build
flutter build appbundle --release --verbose

# Analiza los mensajes para encontrar el error
```

---

## 🎮 Paso 4: Crear App en Play Console

### 4.1 Acceder a Play Console

1. Ve a [Google Play Console](https://play.google.com/console)
2. Login con tu cuenta de Google Developer
3. Acepta términos si es tu primera vez

### 4.2 Crear Nueva Aplicación

**Botón:** "Crear aplicación"

**Información requerida:**

```
Nombre de la aplicación: Chamos Fitness Center

Idioma predeterminado: Español (España) - es-ES

Tipo de aplicación: Aplicación

¿Gratis o de pago?: Gratis

Declaraciones:
✅ Declaro que esta app cumple con las Políticas del Programa para Desarrolladores de Google Play
✅ Declaro que esta app cumple con las leyes de exportación de EE.UU.
```

**Click: "Crear aplicación"**

### 4.3 Panel de Control

Verás un dashboard con tareas pendientes:

```
Panel de control > Chamos Fitness Center

Tareas pendientes para publicar:
□ Configurar tu aplicación
□ Store listing (ficha de Play Store)
□ Clasificación de contenido
□ Público objetivo y contenido
□ Seleccionar países
□ Crear una versión
```

**No te preocupes, iremos paso a paso. 👇**

---

## 📸 Paso 5: Preparar Assets

Antes de continuar, necesitas crear los recursos visuales.

### 5.1 Icon de la App

**Tamaño:** 512 × 512 px  
**Formato:** PNG (32-bit) con transparencia  
**Nombre:** `ic_launcher.png`

**Especificaciones:**
- Diseño plano (flat design)
- Sin degradados complejos
- Legible en tamaños pequeños
- Representa la app claramente

**Herramientas:**
- Canva (gratis)
- Figma (gratis)
- Adobe Illustrator
- [Icon Kitchen](https://icon.kitchen/)

### 5.2 Feature Graphic (Banner)

**Tamaño:** 1024 × 500 px  
**Formato:** PNG o JPG  
**Nombre:** `feature_graphic.png`

**Uso:** Aparece en destacados de Play Store

**Contenido sugerido:**
- Logo de Chamos Fitness
- Slogan: "Tu mejor versión comienza aquí"
- Imágenes de personas entrenando
- Colores del brand: Dorado (#FFD700) y Negro (#0a0a0a)

### 5.3 Screenshots (Capturas de Pantalla)

**Obligatorio:**

**Teléfono:**
- Mínimo: 2 screenshots
- Máximo: 8 screenshots
- Tamaño: Entre 320px y 3840px (ancho o alto)
- Proporción: 16:9 o 9:16
- Formato: PNG o JPG

**Tablet 7"** (opcional):
- Mínimo: 2 screenshots
- Tamaño similar a teléfono

**Recomendaciones:**
```
1. Pantalla de login/registro
2. Dashboard principal
3. Lista de rutinas
4. Ejercicio en progreso
5. Estadísticas y progreso
6. Perfil de usuario
```

**Cómo capturar:**

```bash
# Opción 1: Emulador Android Studio
# Simula un Pixel 6 o similar
# Botón de cámara en el panel lateral

# Opción 2: Dispositivo real
# Abre la app, presiona Power + Volumen Abajo
# Screenshots se guardan en Galería

# Opción 3: Flutter DevTools
flutter run
# En el navegador, click en "Screenshot"
```

**Edición:**
- Agrega marcos de dispositivo con [Device Art Generator](https://developer.android.com/distribute/marketing-tools/device-art-generator)
- Agrega texto descriptivo
- Mantén consistencia de colores

### 5.4 Video Promocional (Opcional)

**YouTube URL:**
- Duración: 30 segundos - 2 minutos
- Muestra funciones principales
- Sube a YouTube como "Unlisted" o "Public"

---

## 🖊️ Paso 6: Configurar Store Listing

En Play Console → **Store listing**

### 6.1 Detalles de la Aplicación

**Nombre de la app:**
```
Chamos Fitness Center
```
*(30 caracteres máximo)*

**Descripción corta:**
```
🏋️ Entrena como un profesional con rutinas personalizadas, 
seguimiento de progreso y nutrición. ¡Tu mejor versión te espera!
```
*(80 caracteres máximo)*

**Descripción completa:**
```
💪 CHAMOS FITNESS CENTER - TU GYM EN EL BOLSILLO

Lleva tu entrenamiento al siguiente nivel con la app oficial de Chamos Fitness Center. Diseñada por entrenadores profesionales para ofrecerte la mejor experiencia de fitness.

🎯 CARACTERÍSTICAS PRINCIPALES:

✓ RUTINAS PERSONALIZADAS
• Planes adaptados a tu nivel: Principiante, Intermedio, Avanzado
• Ejercicios con videos demostrativos profesionales
• Seguimiento detallado de series, repeticiones y descansos
• Especialidades: Fuerza, Volumen y Resistencia

✓ SEGUIMIENTO DE PROGRESO
• Historial completo de entrenamientos
• Estadísticas y gráficos de rendimiento
• Medidas corporales y peso
• Calorías quemadas por sesión

✓ PLANES DE NUTRICIÓN
• Recetas saludables y personalizadas
• Calculadora de calorías y macros
• Planes de alimentación semanales
• Recetas paso a paso con ingredientes

✓ BIBLIOTECA DE EJERCICIOS
• Más de 100 ejercicios documentados
• Videos HD de cada movimiento
• Instrucciones detalladas paso a paso
• Filtrado por grupo muscular y equipo

✓ COMUNIDAD Y MOTIVACIÓN
• Comparte tu progreso con amigos
• Sistema de logros y badges
• Recordatorios personalizados
• Metas y objetivos alcanzables

📊 RESULTADOS COMPROBADOS:
Únete a miles de usuarios que han transformado su cuerpo y salud con Chamos Fitness Center. Ya sea que busques ganar músculo, perder peso o mejorar tu resistencia, tenemos el plan perfecto para ti.

🔒 PRIVACIDAD GARANTIZADA:
Tus datos están protegidos con encriptación de nivel bancario. Cumplimos con GDPR y nunca compartimos tu información personal.

💎 100% GRATIS:
Sin suscripciones ocultas, sin pagos sorpresa. Todo el contenido disponible para ti.

📱 COMPATIBILIDAD:
Funciona en Android 5.0 (Lollipop) y superior. Optimizada para teléfonos y tablets.

¿LISTO PARA TRANSFORMARTE?
Descarga Chamos Fitness Center hoy y comienza tu viaje hacia una vida más saludable y fuerte. ¡Tu mejor versión comienza ahora!

---
SOPORTE Y CONTACTO:
📧 Email: support@chamosfitness.com
🌐 Web: https://chamosfitness.com
📱 Síguenos en redes sociales: @chamosfitness

TÉRMINOS Y PRIVACIDAD:
• Términos de Servicio: https://chamosfitness.com/terms
• Política de Privacidad: https://chamosfitness.com/privacy

© 2026 Chamos Fitness Center. Todos los derechos reservados.
```
*(4000 caracteres máximo)*

### 6.2 Recursos Gráficos

**Subir assets:**

1. **Icon de la app:** `ic_launcher.png` (512×512)
2. **Feature graphic:** `feature_graphic.png` (1024×500)
3. **Screenshots de teléfono:** Mínimo 2 (arrastra y suelta)
4. **Screenshots de tablet:** Opcional
5. **Video de YouTube:** URL (opcional)

### 6.3 Categorización

**Categoría de la aplicación:**
```
Salud y bienestar
```

**Subcategoría:** (si aplica)
```
Fitness
```

**Tags:** (máximo 5)
```
fitness
entrenamiento
gym
rutinas
salud
```

### 6.4 Detalles de Contacto

**Sitio web:**
```
https://chamosfitness.com
(o tu dominio real)
```

**Correo electrónico:**
```
support@chamosfitness.com
```

**Teléfono:** (opcional)
```
+58 XXX XXX XXXX
```

**Dirección:** (opcional pero recomendado)
```
Tu dirección de negocio
```

### 6.5 Política de Privacidad

**URL obligatoria:**
```
https://chamosfitness.com/privacy-policy
```

⚠️ **IMPORTANTE:** Esta URL debe:
- Estar publicada y accesible públicamente
- Explicar qué datos recopilas
- Cómo usas los datos
- Derechos del usuario
- Cumplir con GDPR/CCPA

**Opciones para publicar:**
1. Tu propio sitio web
2. GitHub Pages (gratis)
3. Google Sites (gratis)
4. Generadores como [TermsFeed](https://www.termsfeed.com/)

**Click: "Guardar"**

---

## 🔞 Paso 7: Clasificación de Contenido

En Play Console → **Clasificación de contenido**

### 7.1 Completar Cuestionario

**Click:** "Iniciar cuestionario"

**Dirección de email:**
```
support@chamosfitness.com
```

**Categoría de la aplicación:**
```
☑️ Otra aplicación
```

### 7.2 Preguntas sobre Violencia

```
¿Tu aplicación contiene representaciones realistas de personas 
o animales que mueren, son asesinados, mutilados o dañados 
de otra manera?
❌ No

¿Contiene representaciones de actividades peligrosas que 
podrían dar lugar a lesiones o muerte de los usuarios u otras 
personas del mundo real?
❌ No (entrenar es saludable, no peligroso)
```

### 7.3 Preguntas sobre Sexualidad

```
¿Tu aplicación contiene representaciones sexualmente 
sugerentes o de contenido sexual?
❌ No

¿Contiene referencias sexuales o de humor sexual?
❌ No
```

### 7.4 Preguntas sobre Lenguaje Vulgar

```
¿Tu aplicación contiene lenguaje vulgar o humor desagradable?
❌ No
```

### 7.5 Preguntas sobre Drogas/Alcohol/Tabaco

```
¿Tu aplicación incluye referencias o imágenes sobre el uso 
ilegal de drogas?
❌ No

¿Contiene referencias o imágenes sobre el consumo de alcohol?
❌ No

¿Contiene referencias o imágenes sobre el consumo de tabaco?
❌ No
```

### 7.6 Preguntas sobre Juegos de Azar

```
¿Tu aplicación permite a los usuarios apostar?
❌ No
```

### 7.7 Clasificación Final

**Resultado esperado:**
```
✅ PEGI 3 (Europa)
✅ Everyone (EE.UU.)
✅ Apto para todos los públicos
```

**Click: "Enviar"**

---

## 🎯 Paso 8: Público Objetivo y Contenido

En Play Console → **Público objetivo y contenido**

### 8.1 Público Objetivo

**¿A qué grupo de edad va dirigida tu app?**
```
☑️ Mayores de 13 años
☑️ Adultos
```

**¿Está diseñada tu app específicamente para niños?**
```
❌ No
```

### 8.2 Store Listing de Google Play para Niños

```
❌ No (no aplica si no es para niños)
```

### 8.3 Anuncios

**¿Tu app contiene anuncios?**
```
❌ No (a menos que hayas implementado ads)
```

Si seleccionas Sí, debes declarar qué tipo de anuncios.

### 8.4 Declaraciones Adicionales

**Accesibilidad:**
```
¿Tu aplicación incluye funciones de accesibilidad?
☑️ Sí (declarar cuáles, ej: tamaño de texto ajustable)
□ No
```

**Data Safety (Seguridad de Datos):**

Click en "Administrar"

**¿Recopila tu app datos de usuarios?**
```
☑️ Sí
```

**Tipos de datos recopilados:**

1. **Información personal**
   - ☑️ Nombre
   - ☑️ Email
   - Finalidad: Creación de cuenta, Autenticación

2. **Salud y fitness**
   - ☑️ Información de fitness (entrenamientos, ejercicios)
   - ☑️ Medidas corporales (peso, medidas)
   - Finalidad: Funcionalidad de la app, Analytics

3. **Fotos y videos**
   - ☑️ Fotos (foto de perfil, progreso)
   - Finalidad: Funcionalidad de la app

4. **Identificadores**
   - ☑️ ID de usuario
   - Finalidad: Funcionalidad de la app, Analytics

**¿Se comparten datos con terceros?**
```
□ Sí (solo si usas servicios como Firebase Analytics)
☑️ No
```

**¿Los datos están encriptados en tránsito?**
```
☑️ Sí (HTTPS/TLS)
```

**¿Pueden los usuarios solicitar la eliminación de datos?**
```
☑️ Sí
```

**Link a Privacy Policy:**
```
https://chamosfitness.com/privacy-policy
```

**Click: "Guardar"**

---

## 📦 Paso 9: Subir AAB

En Play Console → **Versiones** → **Producción**

### 9.1 Crear Nueva Versión

**Click:** "Crear nueva versión"

### 9.2 Firma de App

**Google Play App Signing (Recomendado):**
```
☑️ Continuar con Google Play App Signing

Beneficios:
• Google administra la key de signing
• Puedes recuperarla si pierdes tu .jks
• Optimizaciones automáticas
```

**Aceptar términos:** ✅

### 9.3 Subir AAB

**Método 1 - Arrastrar y Soltar:**
1. Abre carpeta: `build\app\outputs\bundle\release\`
2. Arrastra `app-release.aab` a la zona de subida
3. Espera a que se procese (1-5 minutos)

**Método 2 - Botón:**
1. Click "Subir"
2. Navega a `build\app\outputs\bundle\release\app-release.aab`
3. Selecciona y sube

### 9.4 Notas de la Versión

**Idioma:** Español (España)

**Notas de la versión (What's New):**
```
🎉 Primera versión de Chamos Fitness Center

✨ Funcionalidades incluidas:
• Rutinas personalizadas para todos los niveles
• Biblioteca completa de ejercicios con videos
• Seguimiento de progreso y estadísticas
• Planes de nutrición y recetas
• Historial de entrenamientos
• Medidas corporales y peso
• Sistema de logros

💪 ¡Comienza tu transformación hoy!
```
*(500 caracteres máximo)*

### 9.5 Revisión de Versión

Verás un resumen:
```
Nombre de la versión: 1.0.0
Código de versión: 1
Tamaño: ~30 MB (varía según AAB)
SDK mínimo: 21 (Android 5.0)
SDK objetivo: 35 (Android 15)
Permisos: [lista de permisos]
```

**Revisar permisos:**
```
✅ INTERNET
✅ ACCESS_NETWORK_STATE
✅ CAMERA
✅ READ_EXTERNAL_STORAGE
✅ WRITE_EXTERNAL_STORAGE
✅ READ_MEDIA_IMAGES
✅ READ_MEDIA_VIDEO
```

Todos estos son correctos y necesarios.

### 9.6 Guardar y Revisar

**Click: "Guardar"** (NO publiques todavía)

---

## 🧪 Paso 10: Testing

### 10.1 Internal Testing (Pruebas Internas)

**¿Por qué testear?**
- Detectar bugs antes de publicar
- Verificar que funcione en diferentes dispositivos
- Testear flujos completos

**Configurar:**

1. En Play Console → **Versiones** → **Internal testing**
2. **Crear nueva versión**
3. Sube el mismo `app-release.aab`
4. **Guardar**

**Agregar testers:**

1. **Internal testing** → **Testers** tab
2. **Crear lista de emails** → "Beta Testers"
3. Agrega emails (máximo 100 para internal testing):
   ```
   tester1@example.com
   tester2@example.com
   tu-email@example.com
   ```
4. **Guardar**

**Obtener Link de Testing:**

1. Copia el link que aparece
2. Envía a tus testers
3. Ellos deben:
   - Abrir el link en Android
   - Aceptar invitación
   - Descargar desde Play Store

**Duración:** 1-2 días de testing

### 10.2 Closed Testing (Pruebas Cerradas)

**Siguiente nivel:** Hasta 10,000 testers

Solo si quieres más feedback antes de lanzar públicamente.

### 10.3 Open Testing (Pruebas Abiertas)

**Beta pública:** Cualquiera puede unirse

Útil para generar buzz antes del lanzamiento oficial.

---

## 🚀 Paso 11: Publicar en Producción

### 11.1 Revisar TODO el Checklist

En el Dashboard, verifica que TODO esté ✅:

```
✅ Store listing completo
✅ Screenshots subidos
✅ Clasificación de contenido
✅ Público objetivo configurado
✅ Data Safety completo
✅ Países seleccionados
✅ Pricing configurado (Gratis)
✅ AAB subido a Producción
✅ Notas de versión escritas
```

### 11.2 Seleccionar Países

**Distribución:**

**Opción 1 - Todos los países:**
```
☑️ Todos los países disponibles (150+)
```

**Opción 2 - Países específicos:**
```
☑️ Venezuela
☑️ Estados Unidos
☑️ España
☑️ México
☑️ Colombia
☑️ Argentina
... (selecciona los que prefieras)
```

### 11.3 Pricing

```
Esta aplicación es: ⚪ Gratis ⚪ De pago

☑️ Gratis

¿Contiene compras dentro de la app?
□ Sí
☑️ No

¿Contiene anuncios?
□ Sí
☑️ No
```

### 11.4 Enviar a Revisión

**En Producción → Nueva versión**

**Click: "Revisar versión"**

**Última verificación:**
- Todos los campos completos ✅
- AAB subido correctamente ✅
- Sin errores ni advertencias ✅

**Click: "Iniciar lanzamiento en producción"**

### 11.5 Confirmación

```
🎉 ¡Versión enviada a revisión!

Tu app será revisada por Google Play.
Recibirás un email cuando sea aprobada o rechazada.
```

---

## ⏱️ Tiempos de Revisión

### Tiempos Típicos:

| Estado | Tiempo |
|--------|--------|
| **En revisión** | 12-72 horas |
| **Primera app** | 3-7 días (más estricta) |
| **Updates** | 4-24 horas |
| **Rechazos** | Requiere fix y re-envío |

### Durante la Revisión:

**No puedes:**
- Editar store listing
- Cambiar precio
- Modificar países

**Puedes:**
- Preparar próximo update
- Monitorear emails de Google

---

## ✅ Aprobación y Publicación

### Recibirás Email:

```
✅ Tu app "Chamos Fitness Center" ha sido aprobada

Tu app está ahora disponible en Google Play Store
```

### Verificar Publicación:

```
https://play.google.com/store/apps/details?id=com.chamosfitness.app
```

### Lanzamiento Gradual (Opcional):

En lugar de 100% inmediato:
```
Día 1: 5% de usuarios
Día 2: 10% de usuarios
Día 3: 20% de usuarios
Día 4: 50% de usuarios
Día 5: 100% de usuarios
```

**Beneficio:** Detectar problemas antes de afectar a todos.

---

## 📊 Paso 12: Post-Launch

### 12.1 Monitoreo Inmediato (Primeras 24h)

**Revisar:**

1. **Crashes:**
   - Play Console → Calidad → Crashes y ANRs
   - Debe ser < 1% crash rate

2. **Reviews:**
   - Responder TODOS los reviews
   - Especialmente los negativos
   - Dentro de 24-48 horas

3. **Instalaciones:**
   - Dashboard → Estadísticas
   - Usuarios nuevos, retención

### 12.2 Configurar Filtros de Reviews

**Play Console → Crecimiento → Evaluaciones**

**Configurar alertas para:**
- Reviews de 1-2 estrellas (críticos)
- Menciones de crashes
- Palabras clave: "bug", "error", "no funciona"

### 12.3 Responder Reviews

**Ejemplo de respuesta a review positivo:**
```
¡Gracias por tu review! 💪 Nos alegra que estés disfrutando 
de Chamos Fitness Center. Sigue entrenando fuerte!
```

**Ejemplo de respuesta a review negativo:**
```
Lamentamos tu experiencia. 😔 Por favor contáctanos a 
support@chamosfitness.com con más detalles para ayudarte. 
¡Trabajamos constantemente para mejorar!
```

### 12.4 Analytics

**Configurar Firebase Analytics:**

1. Instala Firebase en el proyecto
2. Monitorea:
   - Usuarios activos diarios/mensuales
   - Retención (día 1, 7, 30)
   - Screens más visitados
   - Eventos personalizados

### 12.5 Updates Regulares

**Calendario sugerido:**
```
Semana 1-2: Monitoreo intensivo, fix bugs críticos
Mes 1: Primera actualización (1.0.1)
Cada 2-4 semanas: Updates con mejoras
```

---

## 🔄 Cómo Hacer Updates

### Proceso Simplificado:

1. **Incrementar versión en `pubspec.yaml`:**
   ```yaml
   # Bug fix
   version: 1.0.1+2
   
   # Nuevas features
   version: 1.1.0+3
   ```

2. **Build nuevo AAB:**
   ```bash
   flutter clean
   flutter build appbundle --release
   ```

3. **En Play Console:**
   - Producción → Crear nueva versión
   - Sube nuevo AAB
   - Escribe "What's New"
   - Guardar → Revisar → Publicar

4. **Espera aprobación** (4-24 horas)

---

## 🚨 Troubleshooting

### Error: "Keystore file not found"

```bash
# Solución:
# Verifica la ruta en key.properties
# Debe ser absoluta: D:/ChamosFitnessCenter/android/...
# Usa / en lugar de \
```

### Error: "Wrong password for keystore"

```bash
# Solución:
# Verifica contraseña en key.properties
# Sin espacios, exacta a la que pusiste
# Prueba regenerar si olvidaste la contraseña (pero perderás la key)
```

### Error: "You need to use a different package name"

```bash
# Solución:
# El applicationId ya existe en Play Store
# Cambia en android/app/build.gradle:
# applicationId com.chamosfitness.app.v2 (ejemplo)
```

### App rechazada por "Missing Privacy Policy"

```bash
# Solución:
# Verifica que la URL funcione
# Debe ser accesible públicamente
# Contenido real, no página vacía
```

### Crashes después de publicar

```bash
# Solución:
# Play Console → Calidad → Crashes
# Analiza stack traces
# Fix y sube update ASAP
# Responde a reviews afectados
```

---

## 📈 Optimización ASO (App Store Optimization)

### Título y Descripción

**Usa keywords importantes:**
- fitness, gym, entrenamiento, rutinas
- salud, ejercicio, músculo, nutrición

**Evita:**
- Keyword stuffing
- Caps lock excesivo
- Emojis en el título

### Screenshots

**Best practices:**
- Primero: La pantalla más impresionante
- Texto: Grande, legible, contrastado
- Mostrar la propuesta de valor clara
- Usar imagen y texto combinados

### Icon

**Tests A/B:**
- Probar diferentes versiones
- Colores llamativos
- Diseño simple y reconocible

### Reviews y Ratings

**Estrategia:**
- Pedir reviews solo después de experiencia positiva
- No en primer uso
- No constantemente
- Responder todos los reviews

---

## 📞 Recursos Adicionales

### Documentación Oficial:
- [Play Console Help](https://support.google.com/googleplay/android-developer/)
- [Play Store Policies](https://play.google.com/about/developer-content-policy/)
- [Android Developer Guide](https://developer.android.com/)

### Comunidad:
- [r/androiddev](https://reddit.com/r/androiddev)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/google-play)
- Flutter Discord

### Herramientas Útiles:
- [AppBrain](https://www.appbrain.com/) - ASO tools
- [Mobile Action](https://www.mobileaction.co/) - Analytics
- [Device Art Generator](https://developer.android.com/distribute/marketing-tools/device-art-generator)

---

## ✅ Checklist Final

### Pre-Launch:
- [ ] Signing key generada y respaldada
- [ ] key.properties configurado correctamente
- [ ] AAB generado sin errores
- [ ] Versión correcta (1.0.0+1)
- [ ] Testing en dispositivos reales
- [ ] Sin crashes conocidos

### Play Console:
- [ ] App creada
- [ ] Store listing completo
- [ ] Screenshots (mínimo 2)
- [ ] Icon 512×512
- [ ] Feature graphic 1024×500
- [ ] Descripción completa
- [ ] Clasificación de contenido
- [ ] Data safety completado
- [ ] Privacy policy URL funcionando
- [ ] Países seleccionados
- [ ] AAB subido a producción

### Legal:
- [ ] Privacy Policy publicada
- [ ] Terms of Service publicados
- [ ] Contact email configurado
- [ ] Compliant con GDPR

### Post-Launch:
- [ ] Monitoring configurado (Firebase)
- [ ] Sistema de respuesta a reviews
- [ ] Plan de updates definido
- [ ] Backup de keystore seguro

---

## 🎉 ¡Felicidades!

**Tu app está en Google Play Store! 🚀**

**Próximos pasos:**
1. Compartir link con familia/amigos
2. Marketing y promoción
3. Monitorear métricas
4. Recopilar feedback
5. Planear próximas features

**Link de la app:**
```
https://play.google.com/store/apps/details?id=com.chamosfitness.app
```

**¡Éxito con Chamos Fitness Center! 💪**

---

**Última actualización:** 11 de febrero de 2026  
**Mantenido por:** Equipo Chamos Fitness Center  
**Próxima revisión:** Después del primer update
