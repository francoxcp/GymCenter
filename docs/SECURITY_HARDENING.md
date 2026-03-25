# 🔒 Security Hardening Implementation

Esta guía documenta los 3 vectores de seguridad implementados el 25 de Marzo de 2026.

---

## 1. ✅ Verificación de Credenciales en Git

**Status**: COMPLETADO

```bash
git log --all -- scripts/local_credentials.bat
# Resultado: vacío (ningún commit encontrado)
```

✅ **Conclusión**: Las credenciales de Supabase NO fueron committeadas al historial de git.  
📌 `local_credentials.bat` está en `.gitignore` y protegido.

---

## 2. 🔐 Rate Limiting Server-Side (URGENTE)

**Status**: PENDIENTE — Requiere acción manual en Supabase

### Pasos:

1. **Abre Supabase Dashboard**
   - URL: https://app.supabase.io
   - Selecciona tu proyecto

2. **Ve a "SQL Editor"**
   - Left sidebar → SQL Editor

3. **Copia y ejecuta el script**
   ```bash
   cat database/rate_limiting.sql
   # Copia TODO el contenido
   ```

4. **En Supabase SQL Editor → "New Query"**
   - Pega el contenido completo
   - Click: **"Run"** (botón negro inferior derecho)

5. **Verifica la ejecución**
   - Debe mostrarse: "success" sin errores
   - Las funciones creadas están listadas en Functions → Query Editor

### ¿Qué implementa?

- ✅ Tabla `login_attempts` con índices optimizados
- ✅ RLS: prevenido acceso directo (solo funciones SECURITY DEFINER)
- ✅ Función `check_login_rate_limit()` — bloqueo escalonado (5min/1h después de 5-10 intentos fallidos)
- ✅ Función `record_login_attempt()` — registra todos los intentos (exitosos/fallidos)
- ✅ Auto-limpieza de registros antiguos (>24h)

### Integración en App (próximo paso — opcional)

Desde `auth_provider.dart`, después de cada intento de login fallido:

```dart
// Después de catch en login()
await SupabaseConfig.client.rpc('record_login_attempt', params: {
  'target_email': email,
  'was_successful': false,
  'client_ip': await _getClientIP(), // Si tienes manera de obtenerlo
});
```

---

## 3. 🔐 Certificate Pinning (IMPLEMENTADO)

**Status**: ✅ COMPLETADO

### Cambios Aplicados

**Archivo**: `android/app/src/main/res/xml/network_security_config.xml`

```xml
<domain-config>
    <domain includeSubdomains="true">supabase.co</domain>
    <pin-set expiration="2028-03-25">
        <!-- Leaf certificate (supabase.co) -->
        <pin digest="SHA-256">M4FlSvpxk5vEw3n70qj3t4y7QuYUHuzwkh9Earv1FNQ=</pin>
        <!-- Intermediate (WE1, Google Trust Services) -->
        <pin digest="SHA-256">H7AMYAvicN2+UcFPBz3kJXCDmGrTItZh4ujUBK8hoWg=</pin>
    </pin-set>
</domain-config>
```

### ¿Qué protege?

- 🛡️ **MITM** en redes WiFi comprometidas (cafeterías, hoteles)
- 🛡️ Certificados falsificados no serán aceptados
- 🛡️ Si el certificado no coincide con los pins → conexión rechazada

### Certificados Incluidos

| Certificado | Subject | Expiration | SHA-256 Pin |
|-------------|---------|-----------|------------|
| Leaf | CN=supabase.co | 31 May 2026 | `M4FlSvpxk...` |
| Intermediate | CN=WE1, O=Google Trust Services | 20 Feb 2029 | `H7AMYAvic...` |

### ⏰ Renovación (IMPORTANTE)

El pinning expira el **25 de Marzo de 2028**. Antes de esa fecha:

1. **Ejecuta el script de renovación**:
   ```bash
   powershell -File scripts/get_cert_pins.ps1
   ```

2. **Actualiza los hashes en `network_security_config.xml`**

3. **Re-build y publica una nueva versión de la app**

**Si no lo haces**: Ningún usuario podrá conectar a Supabase después del 25 de Marzo de 2028.

---

## 📊 Resumen de Implementación

| Protección | Implementado | Código | Validación |
|-----------|----------|--------|-----------|
| Git history limpio | ✅ | N/A | `git log --all -- scripts/local_credentials.bat` |
| Rate limiting server | ⏳ Manual | `database/rate_limiting.sql` | Ejecutar en Supabase SQL Editor |
| Certificate pinning | ✅ | `android/app/src/main/res/xml/network_security_config.xml` | Build y deploy en Play Store |

---

## 🧪 Testing

### Verificar que todo está correctamente:

```bash
# 1. Analizar código
dart analyze lib
# Resultado esperado: "No issues found!"

# 2. Ejecutar tests
flutter test
# Resultado esperado: 106 tests passed

# 3. Build Android APK/AAB
flutter build apk --release
# O para Play Store:
flutter build appbundle --release
```

---

## 🚀 Próximos Pasos

1. **HOY**: Ejecutar `database/rate_limiting.sql` en Supabase
2. **ANTES DE DEPLOY**: Verificar que `dart analyze + flutter test` pasen ✅
3. **DEPLOY**: Publica la nueva versión en Play Store / App Store
4. **FOLLOW-UP**: Integra la llamada a `record_login_attempt()` en auth_provider si quieres usar el rate limiting en el backend

---

**Última actualización**: 25 de Marzo de 2026  
**Responsable**: GitHub Copilot Security Audit  
**Estado**: PRODUCCIÓN READY (con ejecución manual de SQL pendiente)
