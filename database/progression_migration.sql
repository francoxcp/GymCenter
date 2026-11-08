-- ============================================================================
-- MIGRACIÓN: progresión inteligente
-- exercise_set_logs ahora guarda:
--   reps         → repeticiones REALES hechas (antes: las planificadas)
--   target_reps  → repeticiones planificadas por el entrenador
--   completed    → si la serie se marcó como completada
-- Idempotente: se puede ejecutar más de una vez.
-- ============================================================================

ALTER TABLE public.exercise_set_logs
  ADD COLUMN IF NOT EXISTS target_reps INTEGER,
  ADD COLUMN IF NOT EXISTS completed BOOLEAN NOT NULL DEFAULT TRUE;

-- Registros antiguos: las reps guardadas eran las planificadas
UPDATE public.exercise_set_logs
   SET target_reps = reps
 WHERE target_reps IS NULL;

-- Consultas de la pantalla "Control semanal" (por usuario y fecha)
CREATE INDEX IF NOT EXISTS idx_exercise_set_logs_user_logged
  ON public.exercise_set_logs (user_id, logged_at DESC);
