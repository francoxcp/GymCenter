-- =====================================================================
-- Limpieza: tablas, columnas y funciones que la app ya no usa.
--   - Planes de alimentación (funcionalidad eliminada)
--   - Metas y valoraciones de rutinas (nunca se conectaron a la app)
--   - Límite de intentos de login en BD (no se usa; Supabase Auth ya
--     limita los intentos)
--   - Funciones RPC sin llamadas desde la app ni desde otras funciones
-- Idempotente: se puede ejecutar más de una vez.
-- =====================================================================
BEGIN;

-- Planes de alimentación
ALTER TABLE public.users DROP COLUMN IF EXISTS assigned_meal_plan_id;
DROP TABLE IF EXISTS public.meal_plans;

-- Metas y valoraciones (sus triggers y políticas se van con la tabla)
DROP TABLE IF EXISTS public.user_goals;
DROP TABLE IF EXISTS public.workout_ratings;
DROP FUNCTION IF EXISTS public.update_user_goals_updated_at();
DROP FUNCTION IF EXISTS public.update_workout_ratings_updated_at();

-- Intentos de login
DROP FUNCTION IF EXISTS public.check_login_rate_limit(TEXT);
DROP FUNCTION IF EXISTS public.record_login_attempt(TEXT, BOOLEAN, TEXT);
DROP FUNCTION IF EXISTS public.cleanup_old_login_attempts();
DROP TABLE IF EXISTS public.login_attempts;

-- RPC sin uso
DROP FUNCTION IF EXISTS public.get_user_role();
DROP FUNCTION IF EXISTS public.list_trainers();

-- Miniaturas de ejercicios: el bucket nunca se usó (se borra desde
-- Storage en el panel; aquí solo su política de lectura)
DROP POLICY IF EXISTS "Exercise thumbnails are publicly accessible" ON storage.objects;

COMMIT;
