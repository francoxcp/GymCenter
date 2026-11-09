-- =====================================================================
-- GYMLAB: sin dificultad en las rutinas y tarea programada renombrada.
-- Ejecutar DESPUÉS de publicar la versión de la app que ya no usa
-- workouts.level. Idempotente.
-- =====================================================================
BEGIN;

ALTER TABLE public.workouts DROP COLUMN IF EXISTS level;

-- Tarea que envía los avisos push: mismo horario, nombre nuevo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'chamos-send-push') THEN
    PERFORM cron.unschedule('chamos-send-push');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'gymlab-send-push') THEN
    PERFORM cron.schedule('gymlab-send-push', '*/5 * * * *',
                          'SELECT public.trigger_send_push();');
  END IF;
END $$;

COMMIT;
