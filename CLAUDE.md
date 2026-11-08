# GymCenter — Chamos Fitness Center

App de gestión de rutinas para gimnasio. **Flutter Web PWA** (se usa desde el móvil, iPhone y Android) publicada en Vercel, con backend **Supabase** (plan gratuito, sin SMTP propio). Android/iOS nativos existen pero no son prioridad.

## Reglas de trabajo
- Todo cambio va en **rama nueva + Pull Request** contra `main`. Nunca push directo a `main`.
- Cambios de base de datos: script SQL nuevo en `database/` (idempotente: `if not exists`, `create or replace`) **+ guía paso a paso** en el PR de qué debe ejecutar el dueño en el panel de Supabase.
- Nunca leer, crear ni subir credenciales: `scripts/local_credentials.bat`, claves de servicio, `.env`.
- Responder en español, conciso. Sin resúmenes largos de lo ya hecho.

## Ahorro de contexto
- No leer `pubspec.lock`, `build/`, `.dart_tool/`, `ios/Pods/`, imágenes ni `docs/*.html`.
- Buscar con Grep/Glob antes de abrir archivos; abrir solo las partes necesarias.
- Para búsquedas amplias usar el subagente `code-finder` (modelo barato) y quedarse con su conclusión.
- Los `docs/` de publicación en tiendas son históricos: ignorarlos salvo que se pida.

## Stack
`provider` (estado) · `go_router` (rutas en `lib/config/router/`) · `supabase_flutter` (auth PKCE + datos) · Sentry · Web Push (VAPID, Edge Function `send-push`).

## Estructura (Feature-First)
- `lib/features/<dominio>/{models,providers,screens,widgets,services}` — dominios: admin, auth, home, legal, onboarding, profile, progress, settings, workouts.
- `lib/shared/services/` — biometría, caché offline (`offline_cache_service`, `offline_sync_queue`), web push, seguridad.
- `lib/shared/widgets/`, `lib/core/` (tema oscuro, constantes, localización es/en).
- `lib/features/workouts/services/progression_engine.dart` — progresión inteligente de pesos.
- `database/` SQL · `supabase/functions/` Edge Functions (create-member, delete-member, reset-member-password, send-push).

## Dominio
- Roles: **dueño / entrenador / socio**. El socio se vincula con código del entrenador; el dueño puede reasignar. Cada entrenador ve solo a sus socios y sus propias rutinas; los entrenadores pueden dar de alta socios.
- Foco: rutinas y ejercicios por semana. **No hay** planes de alimentación (eliminados).
- Toda tabla nueva necesita **RLS** coherente con esos roles.

## Diseño (que no parezca hecho con IA)
Antes de crear o rediseñar UI, escribir en 3–5 líneas la **dirección visual** (concepto, paleta, tipografía, ritmo, un detalle memorable) y seguirla. Aplica a esta app y a cualquier web nueva.
- Identidad GymCenter: gimnasio de barrio, energía y disciplina. Tema oscuro con **un solo color de acento** fuerte; números grandes para pesos, series y progreso, tratados como protagonistas.
- Prohibido por defecto: Inter/Roboto genéricas, degradados morado-azul, tarjetas idénticas con sombra suave y esquinas de 16 px en todo, iconos decorativos sin función, emojis como iconos, textos de relleno ("Bienvenido a tu viaje fitness").
- Sí: jerarquía clara con escala tipográfica marcada, espaciado consistente (múltiplos de 4/8), contraste AA, microinteracciones con propósito (registrar una serie debe sentirse satisfactorio), estados vacíos con personalidad.
- Reutilizar el tema de `lib/core/`; si falta un token (color, radio, espaciado), agregarlo ahí, no hardcodearlo.
- Verificar visualmente (Playwright, viewport 390×844) antes de dar la UI por terminada.

## Comandos
```
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build web --release --no-web-resources-cdn --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
node tool/web_smoke_test.mjs http://localhost:8080   # prueba de humo de la build web
```
CI (`.github/workflows/web.yml`) usa Flutter 3.35.x y ejecuta analyze + test + build en cada PR.

## Antes de dar algo por terminado
`flutter analyze` sin errores y `flutter test` en verde (si Flutter está disponible; si no, decirlo y dejar que lo valide el CI del PR).

## Lecciones aprendidas
<!-- Se agregan con /lecciones. Una línea por lección, la más reciente arriba. Mantener < 20. -->
