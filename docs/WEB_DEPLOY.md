# Guía paso a paso: publicar GymCenter como app web en tu teléfono

Al terminar tendrás la app en una dirección como `https://chamos-fitness.vercel.app`, instalada en la pantalla de inicio de tu iPhone o Android, con notificaciones y desbloqueo con Face ID o huella.

- **Tiempo:** unos 45 minutos la primera vez.
- **Dónde:** desde tu computadora, no desde el teléfono (salvo la PARTE 7).
- **Orden:** sigue las partes en orden. Cada una usa datos de la anterior.

---

## PARTE 0: Preparación

### 0.1 Cuentas que necesitas

| Servicio | ¿Para qué? | ¿Ya la tienes? |
|---|---|---|
| GitHub | Ahí está el código | ✅ Sí |
| Supabase | Base de datos (la que ya usa la app) | ✅ Sí |
| Vercel | Publica la web, gratis | Créala en el paso 1.1 |

### 0.2 Instalar Node.js (una sola vez)

Node.js sirve para ejecutar 3 comandos de esta guía.

1. Entra a **https://nodejs.org**.
2. Descarga el botón que dice **LTS** e instálalo con "Siguiente, Siguiente…" (las opciones por defecto están bien).
3. **Cierra y vuelve a abrir** cualquier terminal que tengas abierta.
4. Comprueba que quedó bien: abre **PowerShell** (tecla Windows, escribe `powershell`, Enter) y escribe:
   ```
   node -v
   ```
   Debe responder algo como `v22.11.0`. Si dice "no se reconoce", reinicia la computadora y prueba otra vez.

### 0.3 Crea tu "hoja de valores"

Abre el Bloc de notas y pega esto. Irás llenando cada línea a medida que avances:

```
VERCEL_TOKEN=
VERCEL_ORG_ID=
VERCEL_PROJECT_ID=
DOMINIO_WEB=
VAPID_PUBLIC_KEY=
VAPID_PRIVATE_KEY=
CRON_SECRET=
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

> 🔒 Este archivo tiene claves secretas. No lo subas a GitHub ni lo compartas. Bórralo al terminar.

---

## PARTE 1: Vercel (dónde se publica la web)

### 1.1 Crear la cuenta

1. Entra a **https://vercel.com/signup**.
2. Elige **Hobby** (gratis), escribe tu nombre y pulsa **Continue with GitHub**. Autoriza.

### 1.2 Crear el proyecto y obtener sus IDs

1. Crea una carpeta vacía en tu escritorio llamada `vercel-setup`.
2. Abre PowerShell **dentro de esa carpeta**: en el Explorador de archivos, entra a la carpeta, haz clic en la barra de dirección, escribe `powershell` y pulsa Enter.
3. Escribe:
   ```
   npx vercel login
   ```
   - Si pregunta `Need to install the following packages... Ok to proceed?`, escribe `y` y Enter.
   - Elige **Continue with GitHub** con las flechas y Enter. Se abrirá el navegador: confirma. Vuelve a PowerShell; debe decir `Congratulations! You are now signed in`.
4. Ahora escribe:
   ```
   npx vercel link
   ```
   Responde así:

   | Pregunta | Respuesta |
   |---|---|
   | `Set up "...vercel-setup"?` | `y` |
   | `Which scope should contain your project?` | Enter (tu cuenta) |
   | `Link to existing project?` | `n` |
   | `What's your project's name?` | `chamos-fitness` |
   | `In which directory is your code located?` | Enter (deja `./`) |
   | `Want to modify these settings?` | `n` |

5. Al terminar se crea una carpeta oculta `.vercel` dentro de `vercel-setup`. Ábrela:
   - En el Explorador: menú **Ver → Mostrar → Elementos ocultos**.
   - Abre `.vercel\project.json` con el Bloc de notas. Verás algo así:
     ```json
     {"projectId":"prj_AbC123...","orgId":"team_XyZ789..."}
     ```
   - Copia `projectId` en **VERCEL_PROJECT_ID** y `orgId` en **VERCEL_ORG_ID** (sin comillas).

### 1.3 Crear el token

1. Entra a **https://vercel.com/account/tokens**.
2. En **Create Token**:
   - **Token Name:** `github-actions`
   - **Scope:** tu cuenta
   - **Expiration:** `No Expiration` (o 1 año)
3. Pulsa **Create**, copia el token que aparece (solo se muestra una vez) y pégalo en **VERCEL_TOKEN**.

### 1.4 Anotar tu dominio

1. Entra a **https://vercel.com/dashboard** y abre el proyecto **chamos-fitness**.
2. Ve a **Settings → Domains**. Verás un dominio como `chamos-fitness.vercel.app` (puede tener letras extra si el nombre estaba ocupado).
3. Cópialo **con** `https://` delante en **DOMINIO_WEB**. Ejemplo: `https://chamos-fitness.vercel.app`.

> Si todavía no aparece ningún dominio, usa `https://chamos-fitness.vercel.app` por ahora. Después del primer despliegue (PARTE 6) revisa que coincida y, si no, corrígelo en el paso 3.6.

---

## PARTE 2: Claves para las notificaciones

1. En PowerShell (en cualquier carpeta) escribe:
   ```
   npx web-push generate-vapid-keys
   ```
   (Si pregunta `Ok to proceed?`, responde `y`.)
2. Verás:
   ```
   Public Key:
   BPx3....(texto largo)
   Private Key:
   k9F2....(texto más corto)
   ```
   Copia el **Public Key** en **VAPID_PUBLIC_KEY** y el **Private Key** en **VAPID_PRIVATE_KEY**.
3. Ahora genera una contraseña aleatoria para el envío automático:
   ```
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```
   Copia el resultado (64 letras y números) en **CRON_SECRET**.

---

## PARTE 3: Supabase

Entra a **https://supabase.com/dashboard** y abre el proyecto de la app.

### 3.1 Copiar la URL y la clave pública

1. Menú izquierdo, abajo: ⚙️ **Project Settings**.
2. Entra en **Data API** (o **API**): copia **Project URL** (`https://xxxx.supabase.co`) en **SUPABASE_URL**.
3. Entra en **API Keys**. Si hay pestañas, elige **Legacy API Keys** y copia la clave **anon public** (empieza por `eyJ...`) en **SUPABASE_ANON_KEY**.

> ⚠️ **No** copies la clave `service_role`: esa es secreta y nunca va en la app.

### 3.2 Guardar dos secretos para el envío automático

1. Menú izquierdo: **SQL Editor** → botón **+** (o **New query**).
2. Pega esto **reemplazando los dos valores** entre comillas simples:
   ```sql
   select vault.create_secret('https://xxxx.supabase.co', 'project_url');
   select vault.create_secret('PEGA_AQUI_TU_CRON_SECRET', 'push_cron_secret');
   ```
   - La primera línea lleva tu **SUPABASE_URL** (sin `/` al final).
   - La segunda lleva tu **CRON_SECRET**.
3. Pulsa **Run** (o Ctrl+Enter). Debe salir `Success`.

> Si sale un error tipo *duplicate key*, ya existían. Bórralos y repite:
> ```sql
> delete from vault.secrets where name in ('project_url','push_cron_secret');
> ```

### 3.3 Activar dos extensiones

1. Menú izquierdo: **Database → Extensions**.
2. Busca `pg_cron` y actívalo con el interruptor. Si pregunta el schema, deja el que sugiere y confirma.
3. Busca `pg_net` y actívalo igual.

### 3.4 Ejecutar la migración (incluye el arreglo de seguridad)

1. En GitHub, abre el archivo del PR: **https://github.com/francoxcp/GymCenter/blob/feature/web-pwa/database/web_pwa_migration.sql**
2. Pulsa el botón **Copy raw file** (ícono de dos hojitas, arriba a la derecha del código).
3. En Supabase: **SQL Editor → New query**, pega todo y pulsa **Run**.
4. Debe terminar con `Success`. Puede mostrar una tabla con un número: es normal.

> **Qué hace:** impide que alguien se registre como administrador (fallo grave que existía), crea la tabla de suscripciones a notificaciones y programa el envío automático cada 15 minutos. Puedes ejecutarla más de una vez sin problema.

**Si nunca lo hiciste**, repite lo mismo con `database/rate_limiting.sql` (protección contra intentos de login masivos):
https://github.com/francoxcp/GymCenter/blob/feature/web-pwa/database/rate_limiting.sql

### 3.5 Crear la función que envía las notificaciones

1. Menú izquierdo: **Edge Functions**.
2. Pulsa **Deploy a new function** → **Via Editor**.
3. Arriba, en el nombre de la función, borra el que trae y escribe exactamente: `send-push`
4. Borra todo el código de ejemplo del editor.
5. En GitHub abre **https://github.com/francoxcp/GymCenter/blob/feature/web-pwa/supabase/functions/send-push/index.ts**, pulsa **Copy raw file** y pégalo en el editor de Supabase.
6. Pulsa **Deploy function** y espera a que diga que se desplegó.
7. **Desactivar la verificación JWT:** dentro de la función `send-push` ve a la pestaña **Details** (o **Settings**), desactiva **Enforce JWT Verification** (o "Verify JWT") y guarda.
   > Esto es necesario porque quien la llama es el reloj automático de la base de datos, no un usuario. La función igual está protegida por tu `CRON_SECRET`.
8. **Agregar los secretos:** en el menú **Edge Functions → Secrets** (o **Manage secrets**), agrega estas 4 filas (**Name** / **Value**) y guarda:

   | Name | Value |
   |---|---|
   | `VAPID_PUBLIC_KEY` | tu VAPID_PUBLIC_KEY |
   | `VAPID_PRIVATE_KEY` | tu VAPID_PRIVATE_KEY |
   | `VAPID_SUBJECT` | `mailto:franco10perez@live.com` |
   | `CRON_SECRET` | tu CRON_SECRET (el mismo del paso 3.2) |

### 3.6 Decirle a Supabase cuál es tu web

1. Menú izquierdo: **Authentication → URL Configuration**.
2. **Site URL**: borra lo que tenga y pega tu **DOMINIO_WEB** (ej. `https://chamos-fitness.vercel.app`). Pulsa **Save**.
3. **Redirect URLs** → **Add URL** → pega tu DOMINIO_WEB seguido de `/**`, ej. `https://chamos-fitness.vercel.app/**` → **Save**.

### 3.7 Cambiar el correo de "Olvidé mi contraseña"

1. Menú izquierdo: **Authentication → Emails** (o **Email Templates**) → pestaña **Reset Password**.
2. En el cuadro **Message body**, busca el texto `{{ .ConfirmationURL }}` (suele estar dentro de `href="..."`).
3. Reemplaza **solo** `{{ .ConfirmationURL }}` por esto:
   ```
   {{ .SiteURL }}/reset-password?token_hash={{ .TokenHash }}&type=recovery
   ```
   Ejemplo de cómo debe quedar el enlace:
   ```html
   <a href="{{ .SiteURL }}/reset-password?token_hash={{ .TokenHash }}&type=recovery">Restablecer contraseña</a>
   ```
   Si `{{ .ConfirmationURL }}` aparece más de una vez, reemplázalo en todos los lugares.
4. Pulsa **Save**.

> **¿Por qué?** En iPhone, la app instalada y Safari no comparten datos. Sin este cambio, el enlace del correo no funcionaría.

---

## PARTE 4: Guardar los secretos en GitHub

1. Abre **https://github.com/francoxcp/GymCenter/settings/secrets/actions**
   (o: en el repositorio, pestaña **Settings** → menú izquierdo **Secrets and variables → Actions**).
2. Pulsa **New repository secret**. En **Name** escribe el nombre exacto (mayúsculas incluidas), en **Secret** pega el valor y pulsa **Add secret**.
3. Repite para cada una de estas 6:

   | Name | Valor de tu hoja |
   |---|---|
   | `SUPABASE_URL` | SUPABASE_URL |
   | `SUPABASE_ANON_KEY` | SUPABASE_ANON_KEY |
   | `VAPID_PUBLIC_KEY` | VAPID_PUBLIC_KEY |
   | `VERCEL_TOKEN` | VERCEL_TOKEN |
   | `VERCEL_ORG_ID` | VERCEL_ORG_ID |
   | `VERCEL_PROJECT_ID` | VERCEL_PROJECT_ID |

4. Al final deben aparecer las 6 en la lista **Repository secrets**.

> ⚠️ **No** pongas aquí `VAPID_PRIVATE_KEY` ni `CRON_SECRET`: esos solo van en Supabase.

---

## PARTE 5: Publicar (merge del Pull Request)

1. Abre **https://github.com/francoxcp/GymCenter/pull/2**
2. Baja hasta el final y pulsa **Merge pull request** → **Confirm merge**.
3. Ve a la pestaña **Actions** del repositorio. Verás una ejecución llamada **"Web (PWA) – build y despliegue"** en amarillo (en progreso).
4. Espera 5–8 minutos hasta que tenga ✅ verde.
5. Entra a la ejecución y abre el paso **Desplegar en Vercel → Desplegar**. Al final verás la dirección publicada.

Desde ahora, **cada cambio que llegue a `main` se publica solo**.

> **Si sale ❌ rojo:** abre el paso con la ❌ y mira el mensaje.
> - *"Faltan secrets…"*: revisa la PARTE 4 (un nombre mal escrito es el error más común).
> - *Vercel dice "Not authorized" o "Project not found"*: revisa que `VERCEL_ORG_ID` y `VERCEL_PROJECT_ID` sean los del archivo `project.json`, sin comillas.

---

## PARTE 6: Comprobar en la computadora

1. Abre tu **DOMINIO_WEB** en Chrome. Debe aparecer el logo amarillo cargando y luego el login.
2. Inicia sesión con tu cuenta. Verifica que ves tus rutinas.
3. Si el dominio que muestra Vercel (PARTE 5, paso 5) no es el que pusiste en el paso 3.6, corrígelo ahora en Supabase (3.6).

---

## PARTE 7: Instalar en el teléfono

### iPhone
1. Abre **Safari** (tiene que ser Safari, no Chrome) y entra a tu DOMINIO_WEB.
2. Toca el botón **Compartir** (cuadro con flecha hacia arriba, abajo en el centro).
3. Desliza y toca **Agregar a pantalla de inicio** → **Agregar**.
4. Cierra Safari y abre la app desde el nuevo ícono amarillo. A partir de ahora úsala siempre desde ese ícono.

### Android
1. Abre **Chrome** y entra a tu DOMINIO_WEB.
2. Inicia sesión. En la pantalla de inicio de la app aparecerá la tarjeta **"Instala Chamos Fitness"**: toca **Instalar**.
   (O: menú **⋮** arriba a la derecha → **Instalar app** / **Agregar a pantalla principal**.)
3. Abre la app desde el nuevo ícono.

### Activar notificaciones (desde la app instalada)
1. **Perfil** → ⚙️ **Configuración** → **Notificaciones**: activa el interruptor.
2. El teléfono preguntará si permites notificaciones: toca **Permitir**.
3. Activa **Recordatorios de entrenamiento** y elige la **hora**.
4. Toca **Probar notificación**: debe llegar una al instante.

### Activar Face ID / huella
1. **Perfil** → ⚙️ **Configuración** → **Privacidad** → **Bloqueo Biométrico**: actívalo.
2. El teléfono pedirá Face ID, huella o PIN para crear la llave: confírmalo.
3. Prueba: sal de la app más de 30 segundos y vuelve. Debe pedir desbloqueo.

---

## Lista de pruebas final

Marca cada una cuando funcione:

- [ ] Registrar un usuario nuevo y completar el onboarding.
- [ ] Cerrar sesión, iniciar sesión y recargar: sigue en la misma pantalla.
- [ ] "Olvidé mi contraseña": llega el correo, el enlace abre la web y permite cambiarla.
- [ ] Rutinas: lista, detalle, entrenar con videos, resumen, historial y calendario.
- [ ] Progreso, medidas corporales y logros.
- [ ] Cambiar foto de perfil con la cámara y desde la galería.
- [ ] Como admin: crear rutina con video, gestionar usuarios y asignar rutinas.
- [ ] Con un usuario normal, escribir `/admin/users` en la dirección: debe volver al inicio.
- [ ] Notificación de prueba.
- [ ] Recordatorio programado: pon la hora 5 minutos adelante y espera hasta 20 minutos (el envío revisa cada 15).
- [ ] Bloqueo con Face ID o huella.
- [ ] Configuración → Exportar mis datos: se descarga un archivo `.enc`.

---

## Problemas comunes

| Problema | Solución |
|---|---|
| La web muestra pantalla negra o error | Revisa en GitHub que los secrets `SUPABASE_URL` y `SUPABASE_ANON_KEY` estén bien y vuelve a ejecutar: **Actions** → la última ejecución → **Re-run all jobs**. |
| En iPhone no aparece la opción de notificaciones | Debes abrir la app **desde el ícono** de la pantalla de inicio, no desde Safari. Requiere iOS 16.4 o posterior. |
| La notificación de prueba funciona, pero el recordatorio no llega | 1) Revisa los 4 secrets de la función (3.5, paso 8). 2) Revisa que **Enforce JWT Verification** esté apagado (3.5, paso 7). 3) En Supabase, **Edge Functions → send-push → Logs**: busca mensajes de error. 4) Ejecuta el paso 3.2 de nuevo si cambiaste el CRON_SECRET. |
| El enlace del correo de contraseña dice "enlace no válido" | Revisa el paso 3.7. Cada enlace sirve una sola vez y caduca: pide uno nuevo. |
| "Face ID / huella" no aparece en Privacidad | El teléfono no tiene bloqueo de pantalla configurado, o el navegador no es compatible. Actualiza el sistema y usa Safari (iPhone) o Chrome (Android). |
| Cambié algo y la app no se actualiza | Cierra la app por completo (deslízala fuera del multitarea) y ábrela de nuevo. |

---

## Notas técnicas (opcional)

- **Qué no existe en web:** el bloqueo de capturas de pantalla (solo Android nativo) y el "atrás dos veces para salir".
- **Planes de alimentación:** se eliminaron de la app. La tabla `meal_plans` sigue en la base de datos por si tenía datos.
- **Versión de Flutter:** el CI compila con **Flutter 3.35.x**, la misma del `pubspec.lock`. Para subirla hay que actualizar dependencias a la vez (por ejemplo `intl`).
- **CLI de Supabase:** si prefieres usarla en lugar del panel, el paso 3.5 equivale a:
  `npx supabase secrets set VAPID_PUBLIC_KEY=... VAPID_PRIVATE_KEY=... VAPID_SUBJECT=mailto:... CRON_SECRET=...` y
  `npx supabase functions deploy send-push --no-verify-jwt`.
