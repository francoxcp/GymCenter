-- =============================================================
-- POLÍTICA DE RETENCIÓN DE DATOS — Chamos Fitness Center
-- Ejecutar una sola vez en el SQL Editor de Supabase.
-- Requiere que pg_cron esté habilitado (Extensions → pg_cron).
-- =============================================================

-- 1. Habilitar extensión pg_cron (si no está activada ya)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Borrar intentos de login con más de 30 días
--    Corre todos los días a las 03:00 UTC
SELECT cron.schedule(
  'purge_login_attempts',
  '0 3 * * *',
  $$
    DELETE FROM public.login_attempts
    WHERE attempted_at < now() - interval '30 days';
  $$
);

-- 3. Borrar notificaciones leídas con más de 60 días
--    Corre todos los días a las 03:05 UTC
SELECT cron.schedule(
  'purge_old_notifications',
  '5 3 * * *',
  $$
    DELETE FROM public.notifications
    WHERE is_read = true
      AND created_at < now() - interval '60 days';
  $$
);

-- 4. (Opcional) Ver los cron jobs registrados
-- SELECT * FROM cron.job;

-- 5. (Opcional) Cancelar un job
-- SELECT cron.unschedule('purge_login_attempts');
