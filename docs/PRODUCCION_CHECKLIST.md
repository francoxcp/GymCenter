# Checklist de Producción - Chamos Fitness Center

## ✅ Configuración de Supabase

### 1. Verificar Credenciales
- [ ] Las credenciales en `.env` son del proyecto de **PRODUCCIÓN** de Supabase
- [ ] `SUPABASE_URL` apunta al proyecto correcto
- [ ] `SUPABASE_ANON_KEY` es la clave correcta (es segura para distribuir)

### 2. Ejecutar Scripts SQL en Supabase
Ve al dashboard de Supabase → SQL Editor y ejecuta en orden:

- [ ] `database/supabase_schema.sql` - Crear todas las tablas, índices y triggers
- [ ] `database/supabase_rls_policies.sql` - Políticas de seguridad (RLS)
- [ ] `database/storage_policies.sql` - Políticas para Storage (imágenes/videos)
- [ ] `database/delete_account_function.sql` - Función para eliminar cuentas

Ver instrucciones detalladas en `database/README.md`

### 3. Configurar Storage en Supabase
Dashboard → Storage → Buckets:

- [ ] Crear bucket `profile-photos` (público: NO)
- [ ] Crear bucket `exercise-videos` (público: SÍ para lectura)
- [ ] Crear bucket `exercise-thumbnails` (público: SÍ)
- [ ] Verificar que las políticas RLS estén aplicadas (ver `storage_policies.sql`)

### 4. Configurar Authentication
Dashboard → Authentication → URL Configuration:

- [ ] Agregar **Site URL**: Tu dominio de producción o `https://chamosfitness.com`
- [ ] Agregar **Redirect URLs**:
  - `io.supabase.chamosfitness://login-callback`
  - `https://chamosfitness.com/**` (si tienes web)
- [ ] **Email Templates**: Personalizar emails de:
  - Confirmación de registro
  - Recuperación de contraseña
  - Cambio de email

Dashboard → Authentication → Providers:
- [ ] **Email** activado
- [ ] Confirmar email: Activado/Desactivado según necesites
- [ ] Configurar **SMTP** personalizado (opcional pero recomendado):
  - Usar Gmail, SendGrid, o AWS SES
  - Evita que emails vayan a spam

### 5. Verificar Row Level Security (RLS)
Dashboard → Database → Tables:

- [ ] Tabla `users` - RLS habilitado ✓
- [ ] Tabla `workouts` - RLS habilitado ✓
- [ ] Tabla `exercises` - RLS habilitado ✓
- [ ] Tabla `meal_plans` - RLS habilitado ✓
- [ ] Tabla `workout_sessions` - RLS habilitado ✓
- [ ] Tabla `user_workouts` - RLS habilitado ✓
- [ ] Tabla `user_meal_plans` - RLS habilitado ✓
- [ ] Tabla `body_measurements` - RLS habilitado ✓
- [ ] Tabla `user_preferences` - RLS habilitado ✓

**Verificar políticas específicas:**
```sql
-- Ejecutar en SQL Editor para revisar
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
```

## ✅ Configuración de la App

### 6. Bundle ID y Nombres
**Android** (`android/app/build.gradle`):
- [ ] `applicationId` cambiado de ejemplo a tu dominio: `com.chamosfitness.app`
- [ ] `versionCode` y `versionName` correctos
- [ ] Firma de la app configurada (keystore)

**iOS** (`ios/Runner/Info.plist`):
- [ ] Bundle Identifier: `com.chamosfitness.app`
- [ ] Versión y build number correctos
- [ ] Permisos configurados (cámara, galería, notificaciones)

### 7. Assets y Recursos
- [ ] Iconos de la app generados para todas las densidades
- [ ] Splash screen configurado
- [ ] Imágenes en `assets/images/` optimizadas (<500KB cada una)
- [ ] Videos de ejemplo (si los hay) con URLs de Supabase

### 8. Configuración de Notificaciones
**Firebase** (si lo usas):
- [ ] Proyecto Firebase creado
- [ ] `google-services.json` en `android/app/` (Android)
- [ ] `GoogleService-Info.plist` en `ios/Runner/` (iOS)
- [ ] Cloud Messaging habilitado

**Local Notifications**:
- [ ] Permisos solicitados en primera ejecución
- [ ] Timezone configurado correctamente
- [ ] Notificaciones de prueba funcionando

### 9. Variables de Entorno
- [ ] Archivo `.env` tiene las credenciales de PRODUCCIÓN
- [ ] `.env` NO está en `.gitignore` si compilas en CI/CD
- [ ] Si usas CI/CD, configura secrets en GitHub Actions / Codemagic

## ✅ Testing Pre-Lanzamiento

### 10. Pruebas Funcionales
- [ ] Registro de usuario nuevo funciona
- [ ] Login funciona
- [ ] Recuperación de contraseña funciona
- [ ] Cambio de foto de perfil funciona
- [ ] Subida de videos (admin) funciona
- [ ] Notificaciones locales funcionan
- [ ] Gráficas de progreso se muestran correctamente

### 11. Pruebas de Seguridad
- [ ] Usuarios normales NO pueden ver datos de otros usuarios
- [ ] Usuarios normales NO pueden subir videos de ejercicios
- [ ] Admins pueden subir videos
- [ ] Eliminar cuenta funciona y borra todos los datos

### 12. Pruebas de Red
- [ ] App funciona con WiFi
- [ ] App funciona con datos móviles
- [ ] Manejo de errores cuando NO hay internet
- [ ] Reintentos automáticos funcionan

### 13. Pruebas de Dispositivos
- [ ] Probado en Android 8+ (API 26+)
- [ ] Probado en iOS 12+
- [ ] Probado en diferentes tamaños de pantalla
- [ ] Orientación portrait funciona (landscape bloqueado)

## ✅ Optimización y Rendimiento

### 14. Build de Producción
**Android**:
```bash
# Opción 1: Usando script automatizado (RECOMENDADO)
scripts\build_production.bat

# Opción 2: Manual - APK Split por ABI
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info

# Opción 3: Manual - App Bundle (Google Play)
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

**iOS**:
```bash
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info
```

- [ ] Build de release sin errores
- [ ] Tamaño del APK/IPA < 50MB
- [ ] Ofuscación de código habilitada ✅
- [ ] ProGuard configurado (Android)
- [ ] Script de build automatizado disponible ✅

### 15. Análisis de Código
```bash
flutter analyze
flutter test
```

- [x] 0 errores en `flutter analyze` ✅ (VERIFICADO)
- [x] Todas las pruebas pasan ✅ (VERIFICADO)
- [x] No hay warnings críticos ✅
- [x] Dependencias optimizadas ✅ (http, dio, flutter_svg eliminados)
- [x] Cache implementado en providers ✅ (5-10 min)
- [x] Lint rules configuradas ✅ (13 reglas activas)

## ✅ Preparación para Tiendas

### 16. Google Play Store
- [ ] Cuenta de desarrollador de Google Play creada ($25 único)
- [ ] Descripción de la app en español/inglés
- [ ] Screenshots (mínimo 2, recomendado 8)
- [ ] Ícono de la app (512x512 PNG)
- [ ] Feature graphic (1024x500)
- [ ] Política de privacidad publicada (URL requerida)
- [ ] Categoría seleccionada: "Salud y Bienestar"
- [ ] Clasificación de contenido completada

### 17. Apple App Store
- [ ] Cuenta de desarrollador de Apple ($99/año)
- [ ] App Store Connect configurado
- [ ] Descripción en español/inglés
- [ ] Screenshots para todos los tamaños de iPhone
- [ ] Ícono de 1024x1024
- [ ] Política de privacidad (URL)
- [ ] Permisos justificados (cámara, notificaciones, etc.)

### 18. Documentos Legales
- [ ] **Política de Privacidad** creada y publicada
  - Debe mencionar que usas Supabase
  - Qué datos recopilas (email, nombre, fotos, mediciones)
  - Cómo se usan los datos
  - Derecho a eliminar cuenta
- [ ] **Términos y Condiciones** (opcional pero recomendado)
- [ ] URLs de estos documentos agregadas en la app

## ✅ Post-Lanzamiento

### 19. Monitoreo
- [ ] Configurar **Sentry** o **Firebase Crashlytics** para crash reporting
- [ ] Dashboard de Supabase → Logs para ver errores
- [ ] Analytics configurado (Firebase Analytics o similar)

### 20. Actualizaciones
- [ ] Plan de mantenimiento mensual
- [ ] Sistema de versionado configurado
- [ ] Canal de beta testing (Google Play: Internal Testing / Apple: TestFlight)

---

## 🔒 Seguridad CRÍTICA

### ⚠️ ANTES DE PUBLICAR:

1. **Verifica RLS en Supabase**:
```sql
-- Ejecuta esto y verifica que TODAS las tablas tienen al menos 1 política
SELECT tablename, COUNT(*) as num_policies
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename;
```

2. **Prueba eliminar datos de otro usuario**:
   - Crea 2 usuarios
   - Intenta desde User A eliminar datos de User B
   - Debe fallar con error de permiso

3. **Verifica que ANON KEY no tenga permisos de admin**:
   - En Supabase Dashboard → Settings → API
   - `anon` key debe tener solo permisos básicos
   - Nunca uses `service_role` key en la app

---

## 📝 Notas Finales

- **La app FUNCIONARÁ en producción** con la configuración actual
- **Supabase ANON KEY es segura** para distribuir en la app
- **La seguridad depende de RLS**, no de ocultar credenciales
- **Ejecuta TODOS los SQL scripts** antes de lanzar

**Última verificación**: Día antes de publicar, ejecuta:
```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Todo debe pasar sin errores.
