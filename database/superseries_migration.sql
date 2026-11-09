-- =====================================================================
-- GYMLAB: superseries (2 a 4 ejercicios seguidos sin descanso entre ellos).
-- Los ejercicios consecutivos de una rutina con el mismo superset_group
-- forman una superserie; sus `sets` son las rondas y `rest_time` el
-- descanso al terminar cada ronda. NULL = ejercicio suelto.
-- Ejecutar ANTES de publicar la versión de la app que guarda superseries.
-- Idempotente. Las políticas RLS de `exercises` ya cubren la columna.
-- =====================================================================
ALTER TABLE public.exercises
  ADD COLUMN IF NOT EXISTS superset_group text;

COMMENT ON COLUMN public.exercises.superset_group IS
  'Ejercicios seguidos con el mismo valor = superserie (sets = rondas).';
