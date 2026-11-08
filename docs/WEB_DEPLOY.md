# GymCenter Web (PWA): guía de puesta en marcha

Esta guía deja la versión web funcionando en tu teléfono (iPhone y Android) sin tiendas de apps.
Hazla en orden: cada paso usa valores del anterior. Tiempo estimado: unos 30–40 minutos.

> Necesitas Node.js instalado en tu PC para los comandos `npx` (https://nodejs.org).

---

## Paso 1: Claves VAPID (para las notificaciones)

En tu PC:

```bash
npx web-push generate-vapid-keys
```

Guarda las dos claves que imprime:

- **Public Key** → `VAPID_PUBLIC_KEY`
- **Private Key** → `VAPID_PRIVATE_KEY` (secreta: nunca la subas al repositorio)

---

## Paso 2: Supabase

### 2.1 Secretos en Vault

Supabase Dashboard → **Project Settings → Vault** → *Add new secret* (crea dos):

| Name | Valor |
|------|-------|
| `project_url` | `https://<tu-proyecto>.supabase.co` |
| `push_cron_secret` | Una contraseña larga inventada por ti (ej. 40 caracteres aleatorios). Anótala: la usas en el 2.3 |

### 2.2 Ejecutar la migración

**SQL Editor → New query**: pega todo `database/web_pwa_migration.sql` y pulsa **Run**.

Esto hace lo siguiente:

- Corrige un fallo de seguridad: antes cualquiera podía registrarse como **admin** enviando `role` en el registro.
- Crea la tabla `push_subscriptions` con sus políticas RLS.
- Añade a `user_preferences` las columnas de hora y zona horaria del recordatorio.
- Programa el envío de notificaciones cada 15 minutos (`pg_cron` + `pg_net`).

> Si da error con `pg_cron` o `pg_net`, actívalas en **Database → Extensions** y vuelve a ejecutar el script; es seguro repetirlo.

Si aún no lo hiciste: ejecuta también `database/rate_limiting.sql`. `docs/SECURITY_HARDENING.md` lo marcaba como pendiente.

### 2.3 Desplegar la Edge Function `send-push`

En tu PC, dentro de la carpeta del proyecto:

```bash
npx supabase login
npx supabase link --project-ref <tu-project-ref>
npx supabase secrets set \
  VAPID_PUBLIC_KEY=<public key del paso 1> \
  VAPID_PRIVATE_KEY=<private key del paso 1> \
  VAPID_SUBJECT=mailto:franco10perez@live.com \
  CRON_SECRET=<el mismo valor de push_cron_secret>
npx supabase functions deploy send-push --no-verify-jwt
```

(`<tu-project-ref>` es la parte `xxxx` de `https://xxxx.supabase.co`.)

### 2.4 URLs de autenticación

**Authentication → URL Configuration**:

- **Site URL**: tu dominio de Vercel, ej. `https://chamos-fitness.vercel.app`. Lo verás en el paso 3; puedes volver a ponerlo después.
- **Redirect URLs**: agrega
  - `https://chamos-fitness.vercel.app/**`
  - `chamosfitnessapp://reset-password` (solo si sigues usando la app móvil)

### 2.5 Plantilla del correo "Reset Password"

**Authentication → Email Templates → Reset Password**. Cambia el enlace del botón por:

```html
<a href="{{ .SiteURL }}/reset-password?token_hash={{ .TokenHash }}&type=recovery">Restablecer contraseña</a>
```

**¿Por qué?** En iPhone, la app instalada y Safari no comparten datos. El enlace del correo se abre en Safari, y el flujo por defecto (PKCE) fallaría. Con `token_hash` funciona en cualquier navegador.

---

## Paso 3: Vercel

1. Crea una cuenta en https://vercel.com (puedes entrar con GitHub).
2. En tu PC crea el proyecto vacío:
   ```bash
   npx vercel login
   npx vercel project add chamos-fitness
   ```
   No conectes el repositorio desde "Import Git Repository": Vercel no trae Flutter y el build fallaría. El build lo hace GitHub Actions y Vercel solo sirve los archivos.
3. Copia estos tres valores:
   - **Token**: Vercel → *Account Settings → Tokens* → *Create* → `VERCEL_TOKEN`
   - **Project ID**: proyecto *chamos-fitness* → *Settings → General* → `VERCEL_PROJECT_ID`
   - **Team/Org ID**: *Settings* de tu cuenta o equipo → *General* → "Vercel ID" o "Team ID" → `VERCEL_ORG_ID`
4. (Opcional) *Settings → Deployment Protection*: desactiva "Vercel Authentication" si quieres abrir las vistas previas de los PR sin iniciar sesión en Vercel.

---

## Paso 4: Secrets en GitHub

Repositorio → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Valor |
|--------|-------|
| `SUPABASE_URL` | `https://<tu-proyecto>.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase → Project Settings → API → `anon` `public` |
| `VAPID_PUBLIC_KEY` | Public Key del paso 1 |
| `VERCEL_TOKEN` | Paso 3 |
| `VERCEL_ORG_ID` | Paso 3 |
| `VERCEL_PROJECT_ID` | Paso 3 |
| `SENTRY_DSN` | Opcional |

Después: **Actions → "Web (PWA) – build y despliegue" → Re-run**, o haz merge del Pull Request. Cada push a `main` publica en producción y cada PR crea una vista previa (el enlace aparece como comentario en el PR).

---

## Paso 5: Instalar en el teléfono

- **iPhone (Safari)**: abre el sitio → botón **Compartir** → **Agregar a pantalla de inicio**. Las notificaciones en iPhone solo funcionan con la app instalada así (iOS 16.4 o posterior).
- **Android (Chrome)**: abre el sitio → aparece la tarjeta **Instalar** en el inicio de la app, o usa el menú ⋮ → *Instalar app*.

Luego, dentro de la app:

- **Perfil → Ajustes → Notificaciones**: actívalas, acepta el permiso y elige la hora del recordatorio.
- **Ajustes → Privacidad → Bloqueo biométrico**: el teléfono pedirá Face ID, huella o PIN para crear la llave (passkey).

---

## Checklist de prueba

- [ ] Registro de usuario nuevo y onboarding.
- [ ] Login, cierre de sesión y recarga de la página: sigue en la misma pantalla.
- [ ] "Olvidé mi contraseña": el correo abre `/reset-password` y te deja cambiarla.
- [ ] Rutinas: lista, detalle, entrenamiento del día con videos, resumen e historial.
- [ ] Progreso, medidas corporales y logros.
- [ ] Foto de perfil desde cámara y galería.
- [ ] Admin: crear rutina con video, gestionar usuarios y asignar rutinas.
- [ ] Un usuario no-admin que escribe `/admin/users` en la URL vuelve a `/home`.
- [ ] Notificación de prueba (Ajustes → "Probar notificación").
- [ ] Recordatorio programado: pon la hora 2–3 minutos adelante y espera (el envío corre cada 15 minutos).
- [ ] Bloqueo biométrico: sal de la app más de 30 segundos y vuelve.
- [ ] Exportar mis datos: se descarga un archivo `.enc`.

## Notas

- **Qué no aplica en web**:
  - El bloqueo de capturas de pantalla (FLAG_SECURE de Android) no existe en navegadores.
  - El botón atrás doble para salir tampoco aplica: lo gestiona el navegador.
- **Sección eliminada**: la app ya no tiene planes de alimentación. La tabla `meal_plans` sigue en la base de datos por si había datos; puedes borrarla cuando quieras.
- **Versión de Flutter**: el CI usa **Flutter 3.35.x**, igual que `pubspec.lock`. Para subir de versión hay que actualizar dependencias a la vez (por ejemplo `intl`).
