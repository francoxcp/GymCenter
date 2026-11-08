-- =====================================================================
-- Endurecimiento tras la QA (avisos del asesor de seguridad de Supabase)
-- Idempotente. No cambia ningún comportamiento de la app.
-- =====================================================================

-- 1. search_path fijo en funciones antiguas
DO $$
DECLARE f TEXT;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.update_workout_ratings_updated_at()',
    'public.update_workout_progress_updated_at()',
    'public.update_user_goals_updated_at()',
    'public.update_updated_at_column()',
    'public.update_workout_exercise_count()',
    'public.update_user_completed_workouts()',
    'public.get_user_role()'
  ] LOOP
    BEGIN
      EXECUTE format('ALTER FUNCTION %s SET search_path = public', f);
    EXCEPTION WHEN undefined_function THEN
      RAISE NOTICE 'No existe %, se omite', f;
    END;
  END LOOP;
END;
$$;

-- 2. Funciones internas: nadie las llama por la API
--    (los triggers y las políticas RLS las siguen usando sin problema)
REVOKE ALL ON FUNCTION public.notify_session_comment() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.notify_session_done() FROM PUBLIC, anon, authenticated;
DO $$
DECLARE f TEXT;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.is_admin()', 'public.is_staff()', 'public.is_trainer()', 'public.my_trainer_id()'
  ] LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', f);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$$;

-- 3. Tablas internas sin acceso desde la app (RLS ya las bloquea; esto
--    además las oculta del esquema GraphQL)
REVOKE ALL ON public.platform_admins FROM anon, authenticated;
REVOKE ALL ON public.push_outbox FROM anon, authenticated;
REVOKE ALL ON public.push_config FROM anon, authenticated;
REVOKE ALL ON public.login_attempts FROM anon, authenticated;
