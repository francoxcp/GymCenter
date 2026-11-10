-- =====================================================================
-- GYMLAB: grupos de ejercicios (superserie o funcional) editables.
--   - group_kind: 'superset' (sin descanso entre ejercicios) o 'functional'
--     (circuito con descanso corto entre ejercicios). NULL en un grupo
--     existente = superserie (compatibilidad con lo ya creado).
--   - group_rest_seconds: descanso entre ejercicios dentro del grupo.
--   - duration_seconds (ya existía, sin uso): si > 0, el ejercicio se hace
--     por tiempo (p. ej. 40 s) en lugar de por repeticiones.
-- El descanso al cerrar cada ronda sigue en rest_time y las rondas en sets.
-- Idempotente. Las políticas RLS de exercises ya cubren las columnas
-- (el entrenador edita solo sus rutinas; el dueño, las de su gimnasio).
-- =====================================================================
ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS group_kind text;
ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS group_rest_seconds integer;
ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS duration_seconds integer;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'exercises_group_kind_check') THEN
    ALTER TABLE public.exercises ADD CONSTRAINT exercises_group_kind_check
      CHECK (group_kind IS NULL OR group_kind IN ('superset', 'functional'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'exercises_group_rest_check') THEN
    ALTER TABLE public.exercises ADD CONSTRAINT exercises_group_rest_check
      CHECK (group_rest_seconds IS NULL OR group_rest_seconds BETWEEN 0 AND 600);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'exercises_duration_check') THEN
    ALTER TABLE public.exercises ADD CONSTRAINT exercises_duration_check
      CHECK (duration_seconds IS NULL OR duration_seconds BETWEEN 0 AND 3600);
  END IF;
END $$;

COMMENT ON COLUMN public.exercises.group_kind IS
  'Tipo de grupo: superset (sin descanso entre ejercicios) o functional (circuito).';
COMMENT ON COLUMN public.exercises.group_rest_seconds IS
  'Descanso entre ejercicios dentro de un grupo funcional (segundos).';
COMMENT ON COLUMN public.exercises.duration_seconds IS
  'Si > 0, el ejercicio se hace por tiempo (segundos) en lugar de por repeticiones.';
