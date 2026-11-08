-- ============================================================================
-- MIGRACIÓN: roles Dueño (admin) / Entrenador (trainer) / Socio (user)
--
-- - Dueño (admin): ve y gestiona todo; nombra entrenadores y reasigna socios.
-- - Entrenador (trainer): ve y gestiona SOLO a sus socios y SUS rutinas
--   (más la biblioteca del gimnasio creada por el dueño).
-- - Socio (user): ve lo suyo; queda vinculado a un entrenador (trainer_id)
--   con el código del entrenador, o porque el entrenador/dueño lo asignó.
--
-- Nadie puede cambiarse el rol ni el entrenador a sí mismo: lo impide el
-- trigger users_guard en la base de datos (no solo la app).
--
-- Reemplaza TODAS las políticas RLS de las tablas listadas en el paso 4 por un
-- conjunto limpio (había políticas duplicadas y algunas demasiado
-- permisivas). Idempotente: se puede ejecutar más de una vez.
-- ============================================================================

BEGIN;

-- 1. Columnas y rol nuevo ----------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS trainer_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS trainer_code TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS users_trainer_code_key
  ON public.users (trainer_code) WHERE trainer_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_trainer_id ON public.users (trainer_id);

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE public.users
  ADD CONSTRAINT users_role_check CHECK (role IN ('admin', 'trainer', 'user'));

-- 2. Funciones auxiliares (SECURITY DEFINER: evitan recursión en RLS) -------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin');
$$;

CREATE OR REPLACE FUNCTION public.is_trainer()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'trainer');
$$;

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'trainer'));
$$;

CREATE OR REPLACE FUNCTION public.my_trainer_id()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT trainer_id FROM public.users WHERE id = auth.uid();
$$;

-- ¿Puede el usuario actual gestionar al usuario p_user? (dueño o su entrenador)
CREATE OR REPLACE FUNCTION public.can_manage_user(p_user UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.is_admin()
      OR EXISTS (
        SELECT 1 FROM public.users u
         WHERE u.id = p_user
           AND u.trainer_id = auth.uid()
           AND public.is_trainer()
      );
$$;

-- ¿Puede el usuario actual ver la rutina? (ver comentario de cabecera)
CREATE OR REPLACE FUNCTION public.can_view_workout(p_workout UUID, p_created_by UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.is_admin()
      OR p_created_by IS NULL                                   -- rutinas antiguas: del gimnasio
      OR p_created_by = auth.uid()                              -- las mías
      OR EXISTS (SELECT 1 FROM public.users c                   -- biblioteca del dueño
                  WHERE c.id = p_created_by AND c.role = 'admin')
      OR p_created_by = public.my_trainer_id()                  -- las de mi entrenador
      OR EXISTS (SELECT 1 FROM public.users me                  -- asignada a mí
                  WHERE me.id = auth.uid() AND me.assigned_workout_id = p_workout)
      OR EXISTS (SELECT 1 FROM public.user_workout_schedule s   -- programada para mí o mis socios
                  WHERE s.workout_id = p_workout
                    AND (s.user_id = auth.uid() OR public.can_manage_user(s.user_id)));
$$;

CREATE OR REPLACE FUNCTION public.gen_trainer_code()
RETURNS TEXT LANGUAGE plpgsql VOLATILE SET search_path = public AS $$
DECLARE
  v_code TEXT;
BEGIN
  LOOP
    -- 6 caracteres sin 0/O/1/I para evitar confusiones al dictarlo
    v_code := '';
    FOR i IN 1..6 LOOP
      v_code := v_code || substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789',
                                 1 + floor(random() * 32)::int, 1);
    END LOOP;
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.users WHERE trainer_code = v_code);
  END LOOP;
  RETURN v_code;
END;
$$;

-- 3. Trigger de protección de rol / entrenador -------------------------------
CREATE OR REPLACE FUNCTION public.users_guard()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  -- auth.uid() nulo = servidor (registro, Edge Functions, SQL Editor)
  IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
    IF TG_OP = 'INSERT' THEN
      NEW.role := 'user';
      NEW.trainer_id := NULL;
      NEW.trainer_code := NULL;
    ELSE
      NEW.role := OLD.role;
      -- Solo las funciones link_trainer_by_code / regenerate_my_trainer_code
      -- pueden cambiar estos campos (activan app.trainer_link)
      IF COALESCE(current_setting('app.trainer_link', true), '') <> '1' THEN
        NEW.trainer_id := OLD.trainer_id;
        NEW.trainer_code := OLD.trainer_code;
      END IF;
    END IF;
  END IF;

  -- El personal siempre tiene código; los socios no lo necesitan
  IF NEW.role IN ('trainer', 'admin') AND NEW.trainer_code IS NULL THEN
    NEW.trainer_code := public.gen_trainer_code();
  ELSIF NEW.role = 'user' THEN
    NEW.trainer_code := NULL;
  END IF;
  -- Un socio no puede ser su propio entrenador
  IF NEW.trainer_id = NEW.id THEN
    NEW.trainer_id := NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS users_guard_trigger ON public.users;
CREATE TRIGGER users_guard_trigger
  BEFORE INSERT OR UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.users_guard();

-- Códigos para el personal existente
UPDATE public.users SET trainer_code = public.gen_trainer_code()
 WHERE role IN ('admin', 'trainer') AND trainer_code IS NULL;

-- Registro: rol siempre 'user'; si trae código de entrenador, se vincula
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_trainer UUID;
BEGIN
  SELECT id INTO v_trainer FROM public.users
   WHERE trainer_code = upper(trim(NEW.raw_user_meta_data->>'trainer_code'))
     AND role IN ('trainer', 'admin')
   LIMIT 1;

  INSERT INTO public.users (id, email, name, role, level, trainer_id)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NULLIF(trim(NEW.raw_user_meta_data->>'name'), ''), 'Usuario Nuevo'),
    'user',
    'Principiante',
    v_trainer
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- 4. Políticas RLS limpias ----------------------------------------------------
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT policyname, tablename FROM pg_policies
     WHERE schemaname = 'public'
       AND tablename IN ('users', 'workouts', 'exercises', 'user_workout_schedule',
                         'body_measurements', 'workout_sessions', 'exercise_set_logs',
                         'user_achievements', 'personal_records')
  LOOP
    EXECUTE format('DROP POLICY %I ON public.%I', r.policyname, r.tablename);
  END LOOP;
END;
$$;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_workout_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_set_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personal_records ENABLE ROW LEVEL SECURITY;

-- users
CREATE POLICY users_select ON public.users FOR SELECT
  USING (id = auth.uid() OR public.can_manage_user(id) OR id = public.my_trainer_id());
CREATE POLICY users_insert ON public.users FOR INSERT
  WITH CHECK (id = auth.uid());
CREATE POLICY users_update ON public.users FOR UPDATE
  USING (id = auth.uid() OR public.can_manage_user(id))
  WITH CHECK (id = auth.uid() OR public.can_manage_user(id));
CREATE POLICY users_delete ON public.users FOR DELETE
  USING (public.is_admin());

-- workouts
CREATE POLICY workouts_select ON public.workouts FOR SELECT
  USING (public.can_view_workout(id, created_by));
-- Cualquiera puede crear SUS rutinas (los socios tienen "Mis rutinas")
CREATE POLICY workouts_insert ON public.workouts FOR INSERT
  WITH CHECK (created_by = auth.uid());
CREATE POLICY workouts_update ON public.workouts FOR UPDATE
  USING (public.is_admin() OR created_by = auth.uid())
  WITH CHECK (public.is_admin() OR created_by = auth.uid());
CREATE POLICY workouts_delete ON public.workouts FOR DELETE
  USING (public.is_admin() OR created_by = auth.uid());

-- exercises (siguen la visibilidad de su rutina)
CREATE POLICY exercises_select ON public.exercises FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.workouts w WHERE w.id = exercises.workout_id));
CREATE POLICY exercises_insert ON public.exercises FOR INSERT
  WITH CHECK (public.is_admin() OR EXISTS (
    SELECT 1 FROM public.workouts w WHERE w.id = exercises.workout_id AND w.created_by = auth.uid()));
CREATE POLICY exercises_update ON public.exercises FOR UPDATE
  USING (public.is_admin() OR EXISTS (
    SELECT 1 FROM public.workouts w WHERE w.id = exercises.workout_id AND w.created_by = auth.uid()));
CREATE POLICY exercises_delete ON public.exercises FOR DELETE
  USING (public.is_admin() OR EXISTS (
    SELECT 1 FROM public.workouts w WHERE w.id = exercises.workout_id AND w.created_by = auth.uid()));

-- user_workout_schedule (rutina por día): la ve el socio, la gestiona su entrenador o el dueño
CREATE POLICY schedule_select ON public.user_workout_schedule FOR SELECT
  USING (user_id = auth.uid() OR public.can_manage_user(user_id));
CREATE POLICY schedule_insert ON public.user_workout_schedule FOR INSERT
  WITH CHECK (public.can_manage_user(user_id));
CREATE POLICY schedule_update ON public.user_workout_schedule FOR UPDATE
  USING (public.can_manage_user(user_id)) WITH CHECK (public.can_manage_user(user_id));
CREATE POLICY schedule_delete ON public.user_workout_schedule FOR DELETE
  USING (public.can_manage_user(user_id));

-- Datos de progreso: los escribe el socio; los lee él, su entrenador y el dueño
CREATE POLICY bm_select ON public.body_measurements FOR SELECT
  USING (user_id = auth.uid() OR public.can_manage_user(user_id));
CREATE POLICY bm_insert ON public.body_measurements FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY bm_update ON public.body_measurements FOR UPDATE
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY bm_delete ON public.body_measurements FOR DELETE
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY ws_select ON public.workout_sessions FOR SELECT
  USING (user_id = auth.uid() OR public.can_manage_user(user_id));
CREATE POLICY ws_insert ON public.workout_sessions FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY ws_update ON public.workout_sessions FOR UPDATE
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY ws_delete ON public.workout_sessions FOR DELETE
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY esl_select ON public.exercise_set_logs FOR SELECT
  USING (user_id = auth.uid() OR public.can_manage_user(user_id));
CREATE POLICY esl_insert ON public.exercise_set_logs FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY esl_delete ON public.exercise_set_logs FOR DELETE
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY ua_select ON public.user_achievements FOR SELECT
  USING (user_id = auth.uid() OR public.can_manage_user(user_id));
CREATE POLICY ua_insert ON public.user_achievements FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY ua_delete ON public.user_achievements FOR DELETE
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY pr_select ON public.personal_records FOR SELECT
  USING (user_id = auth.uid() OR public.can_manage_user(user_id));
CREATE POLICY pr_write ON public.personal_records FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Videos y miniaturas de ejercicios: también los suben los entrenadores
DROP POLICY IF EXISTS staff_insert_exercise_media ON storage.objects;
CREATE POLICY staff_insert_exercise_media ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id IN ('exercise-videos', 'exercise-thumbnails') AND public.is_staff());
DROP POLICY IF EXISTS staff_update_exercise_media ON storage.objects;
CREATE POLICY staff_update_exercise_media ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id IN ('exercise-videos', 'exercise-thumbnails') AND public.is_staff());
DROP POLICY IF EXISTS staff_delete_exercise_media ON storage.objects;
CREATE POLICY staff_delete_exercise_media ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id IN ('exercise-videos', 'exercise-thumbnails') AND public.is_staff());

-- 5. Funciones para la app ----------------------------------------------------

-- El socio se vincula con su entrenador usando el código
CREATE OR REPLACE FUNCTION public.link_trainer_by_code(p_code TEXT)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_trainer RECORD;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not_authenticated'; END IF;
  SELECT id, name INTO v_trainer FROM public.users
   WHERE trainer_code = upper(trim(p_code)) AND role IN ('trainer', 'admin');
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_trainer_code'; END IF;
  IF v_trainer.id = auth.uid() THEN RAISE EXCEPTION 'invalid_trainer_code'; END IF;

  PERFORM set_config('app.trainer_link', '1', true);
  UPDATE public.users SET trainer_id = v_trainer.id WHERE id = auth.uid();
  PERFORM set_config('app.trainer_link', '', true);
  RETURN v_trainer.name;
END;
$$;
REVOKE ALL ON FUNCTION public.link_trainer_by_code(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.link_trainer_by_code(TEXT) TO authenticated;

-- El entrenador genera un código nuevo (p. ej. si el anterior circuló de más)
CREATE OR REPLACE FUNCTION public.regenerate_my_trainer_code()
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_code TEXT;
BEGIN
  IF NOT public.is_staff() THEN RAISE EXCEPTION 'not_allowed'; END IF;
  v_code := public.gen_trainer_code();
  PERFORM set_config('app.trainer_link', '1', true);
  UPDATE public.users SET trainer_code = v_code WHERE id = auth.uid();
  PERFORM set_config('app.trainer_link', '', true);
  RETURN v_code;
END;
$$;
REVOKE ALL ON FUNCTION public.regenerate_my_trainer_code() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.regenerate_my_trainer_code() TO authenticated;

-- Lista de entrenadores (para que el dueño asigne socios)
CREATE OR REPLACE FUNCTION public.list_trainers()
RETURNS TABLE (id UUID, name TEXT, role TEXT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.id, u.name, u.role FROM public.users u
   WHERE u.role IN ('trainer', 'admin') AND public.is_admin()
   ORDER BY u.name;
$$;
REVOKE ALL ON FUNCTION public.list_trainers() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_trainers() TO authenticated;

COMMIT;

SELECT 'ROLES OK' AS resultado,
       (SELECT count(*) FROM public.users WHERE role = 'admin') AS duenos,
       (SELECT count(*) FROM pg_policies WHERE schemaname = 'public'
         AND tablename IN ('users','workouts','exercises','user_workout_schedule')) AS politicas;
