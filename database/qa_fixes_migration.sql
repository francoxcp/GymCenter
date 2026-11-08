-- ============================================================================
-- MIGRACIÓN: correcciones de la auditoría QA (seguridad)
-- Idempotente y en una transacción: si algo falla, no se aplica nada.
-- ============================================================================

BEGIN;

-- #10 Rutinas: nadie sin sesión puede leerlas (antes un anónimo veía la
--     biblioteca del gimnasio y sus ejercicios).
CREATE OR REPLACE FUNCTION public.can_view_workout(p_workout UUID, p_created_by UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT auth.uid() IS NOT NULL AND (
       public.is_admin()
    OR p_created_by IS NULL
    OR p_created_by = auth.uid()
    OR EXISTS (SELECT 1 FROM public.users c WHERE c.id = p_created_by AND c.role = 'admin')
    OR p_created_by = public.my_trainer_id()
    OR EXISTS (SELECT 1 FROM public.users me
                WHERE me.id = auth.uid() AND me.assigned_workout_id = p_workout)
    OR EXISTS (SELECT 1 FROM public.user_workout_schedule s
                WHERE s.workout_id = p_workout
                  AND (s.user_id = auth.uid() OR public.can_manage_user(s.user_id)))
  );
$$;

-- #11 Un usuario no puede asignarse a sí mismo una rutina (solo su
--     entrenador o el dueño). Evita leer rutinas ajenas conociendo su id.
CREATE OR REPLACE FUNCTION public.users_guard()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
    IF TG_OP = 'INSERT' THEN
      NEW.role := 'user';
      NEW.trainer_id := NULL;
      NEW.trainer_code := NULL;
      NEW.assigned_workout_id := NULL;
    ELSE
      NEW.role := OLD.role;
      IF COALESCE(current_setting('app.trainer_link', true), '') <> '1' THEN
        NEW.trainer_id := OLD.trainer_id;
        NEW.trainer_code := OLD.trainer_code;
      END IF;
      -- Sobre su propia fila, nadie (salvo el dueño) cambia la rutina asignada
      IF OLD.id = auth.uid() THEN
        NEW.assigned_workout_id := OLD.assigned_workout_id;
      END IF;
    END IF;
  END IF;

  IF NEW.role IN ('trainer', 'admin') AND NEW.trainer_code IS NULL THEN
    NEW.trainer_code := public.gen_trainer_code();
  ELSIF NEW.role = 'user' THEN
    NEW.trainer_code := NULL;
  END IF;
  IF NEW.trainer_id = NEW.id THEN
    NEW.trainer_id := NULL;
  END IF;
  RETURN NEW;
END;
$$;

-- #7 Funciones internas que no deben poder llamarse desde la app/anónimos
DO $$
DECLARE f TEXT;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.record_login_attempt(text, boolean, text)',
    'public.check_login_rate_limit(text)',
    'public.cleanup_old_login_attempts()',
    'public.gen_trainer_code()',
    'public.handle_new_user()',
    'public.users_guard()'
  ] LOOP
    BEGIN
      EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', f);
    EXCEPTION WHEN undefined_function THEN
      RAISE NOTICE 'No existe %, se omite', f;
    END;
  END LOOP;
END;
$$;

-- Solo usuarios con sesión
REVOKE ALL ON FUNCTION public.delete_user_account(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_user_account(UUID) TO authenticated;
REVOKE ALL ON FUNCTION public.get_user_role() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_user_role() TO authenticated;
REVOKE ALL ON FUNCTION public.get_vapid_public_key() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_vapid_public_key() TO authenticated;
REVOKE ALL ON FUNCTION public.claim_push_subscription(TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.claim_push_subscription(TEXT, TEXT, TEXT) TO authenticated;

-- #15 Restos de planes de alimentación: ya no legibles sin sesión
DROP POLICY IF EXISTS meal_plans_select_all ON public.meal_plans;
DROP POLICY IF EXISTS meal_plans_select_auth ON public.meal_plans;
CREATE POLICY meal_plans_select_auth ON public.meal_plans FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- #5 Límites de tamaño y tipo de archivo en Storage
UPDATE storage.buckets
   SET file_size_limit = 5 * 1024 * 1024,
       allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']
 WHERE id = 'profile-photos';
UPDATE storage.buckets
   SET file_size_limit = 50 * 1024 * 1024,
       allowed_mime_types = ARRAY['video/mp4', 'video/quicktime', 'video/webm', 'video/x-msvideo']
 WHERE id = 'exercise-videos';
UPDATE storage.buckets
   SET file_size_limit = 2 * 1024 * 1024,
       allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']
 WHERE id = 'exercise-thumbnails';

-- #6 Fotos de perfil: cualquier usuario podía LISTAR las fotos de todos.
--    Ahora cada uno lista solo su carpeta (el personal, todas). Las fotos se
--    siguen mostrando por su enlace directo.
DROP POLICY IF EXISTS "Profile photos visible to authenticated users" ON storage.objects;
DROP POLICY IF EXISTS profile_photos_select_scoped ON storage.objects;
CREATE POLICY profile_photos_select_scoped ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'profile-photos'
    AND ((storage.foldername(name))[1] = auth.uid()::text OR public.is_staff())
  );

COMMIT;

SELECT 'QA FIXES OK' AS resultado;
