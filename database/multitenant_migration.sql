-- =====================================================================
-- MULTI-CLIENTE: organizaciones (gimnasios / entrenadores independientes)
--
-- • Cada usuario pertenece a UNA organización (users.org_id).
-- • "Dueño" (role = 'admin') ahora solo ve y gestiona SU organización.
-- • Súper admin de la plataforma (tabla platform_admins): crea clientes,
--   genera su enlace de invitación y revisa los comprobantes de pago.
-- • Invitaciones por enlace de un solo uso (sin correo).
-- • Cobro manual: el dueño sube comprobante → "en revisión" → el súper
--   admin aprueba (al día) o rechaza (pago pendiente, con comentario).
--
-- Requiere las migraciones anteriores (roles, qa_fixes, ux_feed_membership).
-- Idempotente: se puede ejecutar más de una vez.
-- =====================================================================
BEGIN;

-- ---------------------------------------------------------------------
-- 1. Tablas
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.organizations (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name           TEXT NOT NULL CHECK (char_length(btrim(name)) BETWEEN 2 AND 60),
  kind           TEXT NOT NULL DEFAULT 'gym' CHECK (kind IN ('gym', 'independent')),
  logo_url       TEXT,
  status         TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended')),
  plan           TEXT NOT NULL DEFAULT 'Mensual',
  monthly_fee    NUMERIC(10,2) CHECK (monthly_fee IS NULL OR monthly_fee >= 0),
  paid_until     DATE,
  billing_status TEXT NOT NULL DEFAULT 'pending'
                 CHECK (billing_status IN ('pending', 'in_review', 'approved')),
  billing_note   TEXT,
  created_by     UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.platform_admins (
  user_id    UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.platform_admins ENABLE ROW LEVEL SECURITY;  -- sin políticas

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_users_org ON public.users (org_id);

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_workouts_org ON public.workouts (org_id);

CREATE TABLE IF NOT EXISTS public.invitations (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token      TEXT NOT NULL UNIQUE,
  org_id     UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  role       TEXT NOT NULL CHECK (role IN ('admin', 'trainer', 'user')),
  trainer_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  max_uses   INT NOT NULL DEFAULT 1 CHECK (max_uses BETWEEN 1 AND 500),
  uses       INT NOT NULL DEFAULT 0,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked    BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_invitations_org ON public.invitations (org_id, created_at DESC);
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.org_payments (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id         UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  months         INT NOT NULL DEFAULT 1 CHECK (months BETWEEN 1 AND 12),
  amount         NUMERIC(10,2) CHECK (amount IS NULL OR amount >= 0),
  receipt_path   TEXT NOT NULL,
  status         TEXT NOT NULL DEFAULT 'in_review'
                 CHECK (status IN ('in_review', 'approved', 'rejected')),
  review_comment TEXT CHECK (review_comment IS NULL OR char_length(review_comment) <= 500),
  period_start   DATE,
  period_end     DATE,
  submitted_by   UUID REFERENCES public.users(id) ON DELETE SET NULL,
  submitted_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_by    UUID REFERENCES public.users(id) ON DELETE SET NULL,
  reviewed_at    TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_org_payments_org ON public.org_payments (org_id, submitted_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS uq_org_payments_receipt ON public.org_payments (receipt_path);
CREATE INDEX IF NOT EXISTS idx_org_payments_review
  ON public.org_payments (submitted_at) WHERE status = 'in_review';
ALTER TABLE public.org_payments ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------
-- 2. Funciones auxiliares (SECURITY DEFINER, sin recursión en RLS)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT auth.uid() IS NOT NULL
     AND EXISTS (SELECT 1 FROM public.platform_admins WHERE user_id = auth.uid());
$$;

CREATE OR REPLACE FUNCTION public.my_org_id()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT org_id FROM public.users WHERE id = auth.uid();
$$;

-- Organización solo si está activa: un cliente suspendido no accede a
-- datos (sí a su organización y pagos, para poder regularizar)
CREATE OR REPLACE FUNCTION public.my_active_org_id()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.org_id FROM public.users u
    JOIN public.organizations o ON o.id = u.org_id AND o.status = 'active'
   WHERE u.id = auth.uid();
$$;

-- ¿El usuario p_user es de mi misma organización (activa)?
CREATE OR REPLACE FUNCTION public.same_org(p_user UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users u
     WHERE u.id = p_user
       AND u.org_id IS NOT NULL
       AND u.org_id = public.my_active_org_id()
  );
$$;

-- Dueño de la organización de p_user
CREATE OR REPLACE FUNCTION public.owns_member(p_user UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.is_admin() AND public.same_org(p_user);
$$;

-- Dueño de SU organización o entrenador del socio, siempre dentro de la org
CREATE OR REPLACE FUNCTION public.can_manage_user(p_user UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.owns_member(p_user)
      OR (public.is_trainer() AND public.same_org(p_user) AND EXISTS (
            SELECT 1 FROM public.users u
             WHERE u.id = p_user AND u.trainer_id = auth.uid()));
$$;

CREATE OR REPLACE FUNCTION public.can_view_workout(p_workout UUID, p_created_by UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT auth.uid() IS NOT NULL AND (
       p_created_by = auth.uid()
    OR EXISTS (
         SELECT 1 FROM public.workouts w
          WHERE w.id = p_workout
            AND w.org_id IS NOT NULL
            AND w.org_id = public.my_active_org_id()
            AND (
                 public.is_admin()
              OR p_created_by IS NULL
              OR EXISTS (SELECT 1 FROM public.users c
                          WHERE c.id = p_created_by AND c.role = 'admin')
              OR p_created_by = public.my_trainer_id()
              OR EXISTS (SELECT 1 FROM public.users me
                          WHERE me.id = auth.uid() AND me.assigned_workout_id = p_workout)
              OR EXISTS (SELECT 1 FROM public.user_workout_schedule s
                          WHERE s.workout_id = p_workout
                            AND (s.user_id = auth.uid() OR public.can_manage_user(s.user_id)))
            ))
  );
$$;

DO $$
DECLARE f TEXT;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.is_platform_admin()', 'public.my_org_id()', 'public.same_org(uuid)',
    'public.owns_member(uuid)', 'public.my_active_org_id()',
    'public.can_manage_user(uuid)', 'public.can_view_workout(uuid, uuid)'
  ] LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', f);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$$;

-- ---------------------------------------------------------------------
-- 3. Datos actuales → organización "GYMLAB"
-- ---------------------------------------------------------------------
DO $$
DECLARE v_org UUID;
BEGIN
  -- Solo la primera vez: después, los usuarios sin organización son
  -- registros nuevos que esperan una invitación.
  IF NOT EXISTS (SELECT 1 FROM public.organizations) THEN
    INSERT INTO public.organizations (name, kind, plan, paid_until, billing_status, billing_note)
    VALUES ('GYMLAB', 'gym', 'Interno', DATE '2099-12-31', 'approved',
            'Organización de la plataforma')
    RETURNING id INTO v_org;
    UPDATE public.users SET org_id = v_org WHERE org_id IS NULL;
    UPDATE public.workouts w
       SET org_id = COALESCE((SELECT u.org_id FROM public.users u WHERE u.id = w.created_by), v_org)
     WHERE w.org_id IS NULL;
  END IF;
  INSERT INTO public.platform_admins (user_id)
  SELECT id FROM public.users WHERE lower(email) = 'franco10perez@live.com'
  ON CONFLICT DO NOTHING;
END;
$$;

-- ---------------------------------------------------------------------
-- 4. Guardianes (triggers)
-- ---------------------------------------------------------------------
-- users: rol, org, entrenador y membresía protegidos
CREATE OR REPLACE FUNCTION public.users_guard()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_trainer_org UUID;
BEGIN
  IF auth.uid() IS NOT NULL THEN
    IF TG_OP = 'INSERT' THEN
      NEW.role := 'user';
      NEW.trainer_id := NULL;
      NEW.trainer_code := NULL;
      NEW.assigned_workout_id := NULL;
      NEW.membership_plan := NULL;
      NEW.membership_start := NULL;
      NEW.membership_end := NULL;
      NEW.org_id := NULL;
    ELSE
      -- Nadie mueve usuarios entre organizaciones salvo las funciones de
      -- invitación / vínculo por código.
      IF COALESCE(current_setting('app.org_link', true), '') <> '1' THEN
        NEW.org_id := OLD.org_id;
      END IF;
      IF NOT public.is_admin()
         AND COALESCE(current_setting('app.invite_role', true), '') <> '1' THEN
        NEW.role := OLD.role;
        IF COALESCE(current_setting('app.trainer_link', true), '') <> '1' THEN
          NEW.trainer_id := OLD.trainer_id;
          NEW.trainer_code := OLD.trainer_code;
        END IF;
        IF OLD.id = auth.uid() THEN
          NEW.assigned_workout_id := OLD.assigned_workout_id;
        END IF;
        NEW.membership_plan := OLD.membership_plan;
        NEW.membership_start := OLD.membership_start;
        NEW.membership_end := OLD.membership_end;
      END IF;
    END IF;
  END IF;

  -- El entrenador asignado debe ser de la misma organización
  -- (desde el panel SQL / service role, auth.uid() es NULL: sin restricción)
  IF auth.uid() IS NOT NULL AND NEW.trainer_id IS NOT NULL THEN
    SELECT org_id INTO v_trainer_org FROM public.users WHERE id = NEW.trainer_id;
    IF v_trainer_org IS DISTINCT FROM NEW.org_id THEN
      RAISE EXCEPTION 'trainer_other_org' USING ERRCODE = '42501';
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
REVOKE ALL ON FUNCTION public.users_guard() FROM PUBLIC, anon, authenticated;

-- workouts: la organización la pone el servidor
CREATE OR REPLACE FUNCTION public.workouts_org_guard()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF auth.uid() IS NOT NULL THEN
      NEW.org_id := public.my_org_id();
    END IF;
  ELSE
    NEW.org_id := OLD.org_id;
    NEW.created_by := OLD.created_by;
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.workouts_org_guard() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS workouts_org_guard_trigger ON public.workouts;
CREATE TRIGGER workouts_org_guard_trigger
  BEFORE INSERT OR UPDATE ON public.workouts
  FOR EACH ROW EXECUTE FUNCTION public.workouts_org_guard();

-- Registro: si trae código de entrenador, entra a su organización
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_trainer UUID;
  v_org UUID;
BEGIN
  SELECT id, org_id INTO v_trainer, v_org FROM public.users
   WHERE trainer_code = upper(trim(NEW.raw_user_meta_data->>'trainer_code'))
     AND role IN ('trainer', 'admin')
     AND EXISTS (SELECT 1 FROM public.organizations o
                  WHERE o.id = users.org_id AND o.status = 'active')
   LIMIT 1;

  INSERT INTO public.users (id, email, name, role, trainer_id, org_id)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NULLIF(trim(NEW.raw_user_meta_data->>'name'), ''), 'Usuario Nuevo'),
    'user',
    v_trainer,
    v_org
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------
-- 5. Políticas: "dueño" limitado a su organización
-- ---------------------------------------------------------------------
DROP POLICY IF EXISTS users_delete ON public.users;
CREATE POLICY users_delete ON public.users FOR DELETE
  USING (id <> auth.uid() AND public.owns_member(id));

DROP POLICY IF EXISTS workouts_update ON public.workouts;
DROP POLICY IF EXISTS workouts_delete ON public.workouts;
CREATE POLICY workouts_update ON public.workouts FOR UPDATE
  USING (created_by = auth.uid() OR (public.is_admin() AND org_id = public.my_active_org_id()))
  WITH CHECK (created_by = auth.uid() OR (public.is_admin() AND org_id = public.my_active_org_id()));
CREATE POLICY workouts_delete ON public.workouts FOR DELETE
  USING (created_by = auth.uid() OR (public.is_admin() AND org_id = public.my_active_org_id()));

CREATE OR REPLACE FUNCTION public.can_edit_workout(p_workout UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.workouts w
     WHERE w.id = p_workout
       AND (w.created_by = auth.uid()
            OR (public.is_admin() AND w.org_id = public.my_active_org_id()))
  );
$$;
REVOKE ALL ON FUNCTION public.can_edit_workout(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_edit_workout(UUID) TO authenticated;

DROP POLICY IF EXISTS exercises_insert ON public.exercises;
DROP POLICY IF EXISTS exercises_update ON public.exercises;
DROP POLICY IF EXISTS exercises_delete ON public.exercises;
CREATE POLICY exercises_insert ON public.exercises FOR INSERT
  WITH CHECK (public.can_edit_workout(workout_id));
CREATE POLICY exercises_update ON public.exercises FOR UPDATE
  USING (public.can_edit_workout(workout_id)) WITH CHECK (public.can_edit_workout(workout_id));
CREATE POLICY exercises_delete ON public.exercises FOR DELETE
  USING (public.can_edit_workout(workout_id));

DROP POLICY IF EXISTS bm_delete ON public.body_measurements;
CREATE POLICY bm_delete ON public.body_measurements FOR DELETE
  USING (user_id = auth.uid() OR public.owns_member(user_id));
DROP POLICY IF EXISTS ws_delete ON public.workout_sessions;
CREATE POLICY ws_delete ON public.workout_sessions FOR DELETE
  USING (user_id = auth.uid() OR public.owns_member(user_id));
DROP POLICY IF EXISTS esl_delete ON public.exercise_set_logs;
CREATE POLICY esl_delete ON public.exercise_set_logs FOR DELETE
  USING (user_id = auth.uid() OR public.owns_member(user_id));
DROP POLICY IF EXISTS ua_delete ON public.user_achievements;
CREATE POLICY ua_delete ON public.user_achievements FOR DELETE
  USING (user_id = auth.uid() OR public.owns_member(user_id));

DROP POLICY IF EXISTS up_select ON public.user_preferences;
DROP POLICY IF EXISTS up_update ON public.user_preferences;
DROP POLICY IF EXISTS up_delete ON public.user_preferences;
CREATE POLICY up_select ON public.user_preferences FOR SELECT
  USING (auth.uid() = user_id OR public.owns_member(user_id));
CREATE POLICY up_update ON public.user_preferences FOR UPDATE
  USING (auth.uid() = user_id OR public.owns_member(user_id));
CREATE POLICY up_delete ON public.user_preferences FOR DELETE
  USING (auth.uid() = user_id OR public.owns_member(user_id));

DROP POLICY IF EXISTS workout_progress_select_policy ON public.workout_progress;
CREATE POLICY workout_progress_select_policy ON public.workout_progress FOR SELECT
  USING (auth.uid() = user_id OR public.can_manage_user(user_id));
DROP POLICY IF EXISTS workout_ratings_select_policy ON public.workout_ratings;
CREATE POLICY workout_ratings_select_policy ON public.workout_ratings FOR SELECT
  USING (auth.uid() = user_id OR public.owns_member(user_id));

DROP POLICY IF EXISTS mp_select ON public.membership_payments;
DROP POLICY IF EXISTS mp_delete ON public.membership_payments;
CREATE POLICY mp_select ON public.membership_payments FOR SELECT
  USING (user_id = auth.uid() OR public.owns_member(user_id));
CREATE POLICY mp_delete ON public.membership_payments FOR DELETE
  USING (public.owns_member(user_id));

DROP POLICY IF EXISTS sc_delete ON public.session_comments;
CREATE POLICY sc_delete ON public.session_comments FOR DELETE
  USING (author_id = auth.uid()
         OR (public.is_admin() AND public.can_access_session(session_id)));

-- Catálogos globales: solo la plataforma
DROP POLICY IF EXISTS admins_insert_achievements ON public.achievements;
DROP POLICY IF EXISTS admins_update_achievements ON public.achievements;
CREATE POLICY admins_insert_achievements ON public.achievements FOR INSERT
  WITH CHECK (public.is_platform_admin());
CREATE POLICY admins_update_achievements ON public.achievements FOR UPDATE
  USING (public.is_platform_admin());
DROP POLICY IF EXISTS meal_plans_insert_admin ON public.meal_plans;
DROP POLICY IF EXISTS meal_plans_update_admin ON public.meal_plans;
DROP POLICY IF EXISTS meal_plans_delete_admin ON public.meal_plans;

-- Fotos de perfil: solo las de mis socios / mi entrenador
CREATE OR REPLACE FUNCTION public.can_view_user_folder(p_folder TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF p_folder = auth.uid()::text THEN RETURN true; END IF;
  RETURN public.can_manage_user(p_folder::uuid)
      OR p_folder::uuid = public.my_trainer_id();
EXCEPTION WHEN others THEN
  RETURN false;
END;
$$;
REVOKE ALL ON FUNCTION public.can_view_user_folder(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_view_user_folder(TEXT) TO authenticated;
DROP POLICY IF EXISTS profile_photos_select_scoped ON storage.objects;
CREATE POLICY profile_photos_select_scoped ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'profile-photos'
         AND public.can_view_user_folder((storage.foldername(name))[1]));

-- Políticas antiguas de videos que dependían de role = 'admin' global
DROP POLICY IF EXISTS "Admins can delete exercise videos" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update exercise videos" ON storage.objects;
DROP POLICY IF EXISTS "Admins can upload exercise thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Admins can upload exercise videos" ON storage.objects;

-- Videos/miniaturas de ejercicios: cada quien borra/edita lo suyo (o el
-- dueño lo de su organización), no lo de otros gimnasios
DROP POLICY IF EXISTS staff_update_exercise_media ON storage.objects;
DROP POLICY IF EXISTS staff_delete_exercise_media ON storage.objects;
CREATE POLICY staff_update_exercise_media ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id IN ('exercise-videos', 'exercise-thumbnails')
         AND public.is_staff()
         AND (owner = auth.uid() OR public.owns_member(owner)));
CREATE POLICY staff_delete_exercise_media ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id IN ('exercise-videos', 'exercise-thumbnails')
         AND public.is_staff()
         AND (owner = auth.uid() OR public.owns_member(owner)));

-- Organizaciones, invitaciones y pagos
-- Los socios y entrenadores solo ven nombre, tipo, logo y estado; el cobro
-- lo ve el dueño con get_my_org_billing()
REVOKE SELECT ON public.organizations FROM anon, authenticated;
GRANT SELECT (id, name, kind, logo_url, status) ON public.organizations TO authenticated;

DROP POLICY IF EXISTS org_select ON public.organizations;
CREATE POLICY org_select ON public.organizations FOR SELECT
  USING (id = public.my_org_id() OR public.is_platform_admin());
-- (sin INSERT/UPDATE/DELETE directos: solo con las funciones de abajo)

DROP POLICY IF EXISTS inv_select ON public.invitations;
CREATE POLICY inv_select ON public.invitations FOR SELECT
  USING (public.is_platform_admin()
         OR created_by = auth.uid()
         OR (public.is_admin() AND org_id = public.my_org_id()));

DROP POLICY IF EXISTS op_select ON public.org_payments;
CREATE POLICY op_select ON public.org_payments FOR SELECT
  USING (public.is_platform_admin()
         OR (public.is_admin() AND org_id = public.my_org_id()));

-- ---------------------------------------------------------------------
-- 6. Funciones existentes ajustadas a la organización
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.list_trainers()
RETURNS TABLE(id UUID, name TEXT, role TEXT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.id, u.name, u.role FROM public.users u
   WHERE u.role IN ('trainer', 'admin')
     AND public.is_admin()
     AND u.org_id = public.my_org_id()
   ORDER BY u.name;
$$;

CREATE OR REPLACE FUNCTION public.link_trainer_by_code(p_code TEXT)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_trainer RECORD;
  v_my_org UUID;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not_authenticated'; END IF;
  v_my_org := public.my_org_id();
  SELECT u.id, u.name, u.org_id INTO v_trainer FROM public.users u
    JOIN public.organizations o ON o.id = u.org_id AND o.status = 'active'
   WHERE u.trainer_code = upper(trim(p_code)) AND u.role IN ('trainer', 'admin');
  -- Mismo error en todos los casos: no permite averiguar códigos válidos
  IF NOT FOUND OR v_trainer.id = auth.uid()
     OR (v_my_org IS NOT NULL AND v_my_org <> v_trainer.org_id) THEN
    RAISE EXCEPTION 'invalid_trainer_code';
  END IF;
  IF public.is_staff() AND v_my_org IS NOT NULL THEN
    RAISE EXCEPTION 'invalid_trainer_code';
  END IF;

  PERFORM set_config('app.trainer_link', '1', true);
  PERFORM set_config('app.org_link', '1', true);
  UPDATE public.users SET org_id = v_trainer.org_id, trainer_id = v_trainer.id
   WHERE id = auth.uid();
  PERFORM set_config('app.trainer_link', '', true);
  PERFORM set_config('app.org_link', '', true);
  RETURN v_trainer.name;
END;
$$;
REVOKE ALL ON FUNCTION public.link_trainer_by_code(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.link_trainer_by_code(TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.renew_membership(
  p_user UUID, p_plan TEXT, p_months INT, p_amount NUMERIC DEFAULT NULL
) RETURNS DATE LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_today DATE := (now() AT TIME ZONE 'America/Costa_Rica')::date;
  v_end   DATE;
  v_start DATE;
  v_new   DATE;
BEGIN
  IF NOT public.owns_member(p_user) THEN
    RAISE EXCEPTION 'Solo el dueño puede registrar membresías' USING ERRCODE = '42501';
  END IF;
  IF p_months IS NULL OR p_months < 1 OR p_months > 24 THEN
    RAISE EXCEPTION 'Meses inválidos';
  END IF;
  IF p_plan IS NULL OR char_length(btrim(p_plan)) = 0 OR char_length(p_plan) > 40 THEN
    RAISE EXCEPTION 'Plan inválido';
  END IF;

  SELECT membership_end INTO v_end FROM public.users WHERE id = p_user FOR UPDATE;
  v_start := CASE WHEN v_end IS NOT NULL AND v_end >= v_today THEN v_end + 1 ELSE v_today END;
  v_new := (v_start + make_interval(months => p_months))::date - 1;

  UPDATE public.users
     SET membership_plan = btrim(p_plan),
         membership_start = CASE WHEN v_end IS NOT NULL AND v_end >= v_today
                                 THEN COALESCE(membership_start, v_start) ELSE v_start END,
         membership_end = v_new
   WHERE id = p_user;

  INSERT INTO public.membership_payments
    (user_id, plan, amount, period_start, period_end, created_by)
  VALUES (p_user, btrim(p_plan), p_amount, v_start, v_new, auth.uid());
  RETURN v_new;
END;
$$;
REVOKE ALL ON FUNCTION public.renew_membership(UUID, TEXT, INT, NUMERIC) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.renew_membership(UUID, TEXT, INT, NUMERIC) TO authenticated;

-- ---------------------------------------------------------------------
-- 7. Invitaciones
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.gen_invite_token()
RETURNS TEXT LANGUAGE plpgsql VOLATILE SET search_path = public AS $$
DECLARE v TEXT;
BEGIN
  LOOP
    v := '';
    FOR i IN 1..10 LOOP
      v := v || substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789',
                       1 + (get_byte(extensions.gen_random_bytes(1), 0) % 32), 1);
    END LOOP;
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.invitations WHERE token = v);
  END LOOP;
  RETURN v;
END;
$$;
REVOKE ALL ON FUNCTION public.gen_invite_token() FROM PUBLIC, anon, authenticated;

-- Crea un enlace de invitación.
--   'admin'   → solo la plataforma, para el dueño de un cliente (1 uso, 7 días)
--   'trainer' → dueño de un gimnasio (1 uso, 7 días)
--   'user'    → dueño o entrenador, para sus socios (hasta 100 usos, 30 días)
CREATE OR REPLACE FUNCTION public.create_invitation(p_role TEXT, p_org UUID DEFAULT NULL)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_org   UUID;
  v_kind  TEXT;
  v_token TEXT;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not_authenticated'; END IF;
  IF p_role = 'admin' THEN
    IF NOT public.is_platform_admin() OR p_org IS NULL THEN
      RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
    END IF;
    v_org := p_org;
  ELSIF p_role = 'trainer' THEN
    v_org := public.my_org_id();
    SELECT kind INTO v_kind FROM public.organizations WHERE id = v_org;
    IF NOT public.is_admin() OR v_org IS NULL OR v_kind <> 'gym' THEN
      RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
    END IF;
  ELSIF p_role = 'user' THEN
    v_org := public.my_org_id();
    IF NOT public.is_staff() OR v_org IS NULL THEN
      RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
    END IF;
  ELSE
    RAISE EXCEPTION 'invalid_role';
  END IF;

  v_token := public.gen_invite_token();
  INSERT INTO public.invitations (token, org_id, role, trainer_id, created_by, max_uses, expires_at)
  VALUES (v_token, v_org, p_role,
          CASE WHEN p_role = 'user' THEN auth.uid() END,
          auth.uid(),
          CASE WHEN p_role = 'user' THEN 100 ELSE 1 END,
          now() + CASE WHEN p_role = 'user' THEN interval '30 days' ELSE interval '7 days' END);
  RETURN v_token;
END;
$$;
REVOKE ALL ON FUNCTION public.create_invitation(TEXT, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_invitation(TEXT, UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.revoke_invitation(p_token TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE public.invitations SET revoked = true
   WHERE token = p_token
     AND (created_by = auth.uid() OR public.is_platform_admin()
          OR (public.is_admin() AND org_id = public.my_org_id()));
END;
$$;
REVOKE ALL ON FUNCTION public.revoke_invitation(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.revoke_invitation(TEXT) TO authenticated;

-- Datos públicos mínimos para la pantalla "Te invitaron a …" (sin sesión)
CREATE OR REPLACE FUNCTION public.invitation_info(p_token TEXT)
RETURNS TABLE(org_name TEXT, org_logo TEXT, org_kind TEXT, role TEXT, valid BOOLEAN)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT o.name, o.logo_url, o.kind, i.role,
         (NOT i.revoked AND i.uses < i.max_uses AND i.expires_at > now()
          AND o.status = 'active')
    FROM public.invitations i
    JOIN public.organizations o ON o.id = i.org_id
   WHERE i.token = upper(trim(p_token));
$$;
REVOKE ALL ON FUNCTION public.invitation_info(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.invitation_info(TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.accept_invitation(p_token TEXT)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_inv  RECORD;
  v_me   RECORD;
  v_org_name TEXT;
  v_new_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not_authenticated'; END IF;
  SELECT * INTO v_inv FROM public.invitations
   WHERE token = upper(trim(p_token)) FOR UPDATE;
  IF NOT FOUND OR v_inv.revoked OR v_inv.uses >= v_inv.max_uses OR v_inv.expires_at <= now() THEN
    RAISE EXCEPTION 'invalid_invitation';
  END IF;
  SELECT name INTO v_org_name FROM public.organizations
   WHERE id = v_inv.org_id AND status = 'active';
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_invitation'; END IF;

  SELECT id, role, org_id INTO v_me FROM public.users WHERE id = auth.uid() FOR UPDATE;
  IF v_me.org_id IS NOT NULL AND v_me.org_id <> v_inv.org_id THEN
    RAISE EXCEPTION 'already_in_other_org';
  END IF;

  -- Nunca baja de rol: un dueño que abre un enlace de socio sigue siendo dueño
  v_new_role := CASE
    WHEN v_inv.role = 'admin' THEN 'admin'
    WHEN v_inv.role = 'trainer' AND v_me.role = 'user' THEN 'trainer'
    ELSE v_me.role END;

  -- Ya es miembro con ese rol: no gasta usos ni cambia su entrenador
  IF v_me.org_id = v_inv.org_id AND v_new_role = v_me.role THEN
    RETURN v_org_name;
  END IF;

  PERFORM set_config('app.org_link', '1', true);
  PERFORM set_config('app.invite_role', '1', true);
  PERFORM set_config('app.trainer_link', '1', true);
  UPDATE public.users
     SET org_id = v_inv.org_id,
         role = v_new_role,
         trainer_id = CASE
           WHEN v_new_role <> 'user' THEN NULL
           WHEN v_inv.role = 'user' THEN COALESCE(trainer_id, v_inv.trainer_id)
           ELSE trainer_id END
   WHERE id = auth.uid();
  PERFORM set_config('app.org_link', '', true);
  PERFORM set_config('app.invite_role', '', true);
  PERFORM set_config('app.trainer_link', '', true);

  UPDATE public.invitations SET uses = uses + 1 WHERE id = v_inv.id;
  RETURN v_org_name;
END;
$$;
REVOKE ALL ON FUNCTION public.accept_invitation(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_invitation(TEXT) TO authenticated;

-- ---------------------------------------------------------------------
-- 8. Organización: datos, marca y administración de la plataforma
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_my_org(p_name TEXT, p_logo_url TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_org UUID := public.my_org_id();
BEGIN
  IF NOT public.is_admin() OR v_org IS NULL THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  IF p_logo_url IS NOT NULL AND p_logo_url !~ (
       '^https://[a-z0-9]+\.supabase\.co/storage/v1/object/public/org-logos/'
       || v_org::text || '/[A-Za-z0-9._-]+$') THEN
    RAISE EXCEPTION 'invalid_logo';
  END IF;
  UPDATE public.organizations
     SET name = COALESCE(NULLIF(btrim(p_name), ''), name),
         logo_url = COALESCE(p_logo_url, logo_url)
   WHERE id = v_org;
END;
$$;
REVOKE ALL ON FUNCTION public.update_my_org(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_my_org(TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_my_org_billing()
RETURNS TABLE(plan TEXT, monthly_fee NUMERIC, paid_until DATE,
              billing_status TEXT, billing_note TEXT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT o.plan, o.monthly_fee, o.paid_until, o.billing_status, o.billing_note
    FROM public.organizations o
   WHERE o.id = public.my_org_id() AND public.is_admin();
$$;
REVOKE ALL ON FUNCTION public.get_my_org_billing() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_org_billing() TO authenticated;

-- Plataforma: alta de un cliente + enlace para su dueño
CREATE OR REPLACE FUNCTION public.platform_create_org(
  p_name TEXT, p_kind TEXT, p_monthly_fee NUMERIC DEFAULT NULL, p_trial_days INT DEFAULT 14
) RETURNS TABLE(org_id UUID, token TEXT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_org UUID;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.organizations (name, kind, monthly_fee, paid_until, billing_status,
                                    billing_note, created_by)
  VALUES (btrim(p_name), p_kind, p_monthly_fee,
          (now() AT TIME ZONE 'America/Costa_Rica')::date + GREATEST(COALESCE(p_trial_days, 0), 0),
          CASE WHEN COALESCE(p_trial_days, 0) > 0 THEN 'approved' ELSE 'pending' END,
          CASE WHEN COALESCE(p_trial_days, 0) > 0 THEN 'Periodo de prueba' END,
          auth.uid())
  RETURNING id INTO v_org;
  RETURN QUERY SELECT v_org, public.create_invitation('admin', v_org);
END;
$$;
REVOKE ALL ON FUNCTION public.platform_create_org(TEXT, TEXT, NUMERIC, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_create_org(TEXT, TEXT, NUMERIC, INT) TO authenticated;

CREATE OR REPLACE FUNCTION public.platform_set_org_status(p_org UUID, p_status TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  UPDATE public.organizations SET status = p_status WHERE id = p_org;
END;
$$;
REVOKE ALL ON FUNCTION public.platform_set_org_status(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_set_org_status(UUID, TEXT) TO authenticated;

-- Plataforma: listado de clientes con su dueño y conteos
CREATE OR REPLACE FUNCTION public.platform_list_orgs()
RETURNS TABLE(id UUID, name TEXT, kind TEXT, logo_url TEXT, status TEXT,
              billing_status TEXT, billing_note TEXT, paid_until DATE,
              monthly_fee NUMERIC, owner_name TEXT, owner_email TEXT,
              trainers BIGINT, members BIGINT, pending_reviews BIGINT,
              created_at TIMESTAMPTZ)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT o.id, o.name, o.kind, o.logo_url, o.status, o.billing_status, o.billing_note,
         o.paid_until, o.monthly_fee,
         (SELECT u.name FROM public.users u WHERE u.org_id = o.id AND u.role = 'admin'
           ORDER BY u.created_at LIMIT 1),
         (SELECT u.email FROM public.users u WHERE u.org_id = o.id AND u.role = 'admin'
           ORDER BY u.created_at LIMIT 1),
         (SELECT count(*) FROM public.users u WHERE u.org_id = o.id AND u.role = 'trainer'),
         (SELECT count(*) FROM public.users u WHERE u.org_id = o.id AND u.role = 'user'),
         (SELECT count(*) FROM public.org_payments p WHERE p.org_id = o.id AND p.status = 'in_review'),
         o.created_at
    FROM public.organizations o
   WHERE public.is_platform_admin()
   ORDER BY (SELECT count(*) FROM public.org_payments p
              WHERE p.org_id = o.id AND p.status = 'in_review') DESC, o.name;
$$;
REVOKE ALL ON FUNCTION public.platform_list_orgs() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_list_orgs() TO authenticated;

-- ---------------------------------------------------------------------
-- 9. Cobro manual con comprobante
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_org_payment(
  p_months INT, p_amount NUMERIC, p_receipt_path TEXT
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_org  UUID := public.my_org_id();
  v_name TEXT;
  v_id   UUID;
BEGIN
  IF NOT public.is_admin() OR v_org IS NULL THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  IF p_receipt_path IS NULL OR split_part(p_receipt_path, '/', 1) <> v_org::text THEN
    RAISE EXCEPTION 'invalid_receipt';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM storage.objects
                  WHERE bucket_id = 'payment-receipts' AND name = p_receipt_path) THEN
    RAISE EXCEPTION 'receipt_not_found';
  END IF;
  IF EXISTS (SELECT 1 FROM public.org_payments
              WHERE org_id = v_org AND status = 'in_review') THEN
    RAISE EXCEPTION 'payment_already_in_review';
  END IF;

  INSERT INTO public.org_payments (org_id, months, amount, receipt_path, submitted_by)
  VALUES (v_org, COALESCE(p_months, 1), p_amount, p_receipt_path, auth.uid())
  RETURNING id INTO v_id;

  UPDATE public.organizations SET billing_status = 'in_review', billing_note = NULL
   WHERE id = v_org
  RETURNING name INTO v_name;

  -- Alerta a la plataforma
  INSERT INTO public.push_outbox (user_id, title, body, url, tag)
  SELECT pa.user_id, '🧾 Comprobante por revisar',
         v_name || ' subió un pago de ' || COALESCE(p_months, 1) || ' mes(es)',
         '/platform', 'org_payment'
    FROM public.platform_admins pa;
  RETURN v_id;
END;
$$;
REVOKE ALL ON FUNCTION public.submit_org_payment(INT, NUMERIC, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_org_payment(INT, NUMERIC, TEXT) TO authenticated;

-- La plataforma aprueba (al día) o rechaza (pago pendiente + motivo)
CREATE OR REPLACE FUNCTION public.review_org_payment(
  p_payment UUID, p_approve BOOLEAN, p_comment TEXT DEFAULT NULL
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_pay   RECORD;
  v_today DATE := (now() AT TIME ZONE 'America/Costa_Rica')::date;
  v_paid  DATE;
  v_start DATE;
  v_end   DATE;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_pay FROM public.org_payments WHERE id = p_payment FOR UPDATE;
  IF NOT FOUND OR v_pay.status <> 'in_review' THEN
    RAISE EXCEPTION 'payment_not_in_review';
  END IF;
  IF NOT p_approve AND char_length(btrim(COALESCE(p_comment, ''))) < 3 THEN
    RAISE EXCEPTION 'comment_required';
  END IF;

  IF p_approve THEN
    SELECT paid_until INTO v_paid FROM public.organizations WHERE id = v_pay.org_id FOR UPDATE;
    v_start := CASE WHEN v_paid IS NOT NULL AND v_paid >= v_today THEN v_paid + 1 ELSE v_today END;
    v_end := (v_start + make_interval(months => v_pay.months))::date - 1;
    UPDATE public.org_payments
       SET status = 'approved', review_comment = NULLIF(btrim(p_comment), ''),
           period_start = v_start, period_end = v_end,
           reviewed_by = auth.uid(), reviewed_at = now()
     WHERE id = p_payment;
    UPDATE public.organizations
       SET paid_until = v_end, billing_status = 'approved',
           billing_note = NULLIF(btrim(p_comment), ''), status = 'active'
     WHERE id = v_pay.org_id;
  ELSE
    UPDATE public.org_payments
       SET status = 'rejected', review_comment = btrim(p_comment),
           reviewed_by = auth.uid(), reviewed_at = now()
     WHERE id = p_payment;
    UPDATE public.organizations
       SET billing_status = CASE WHEN paid_until >= v_today THEN 'approved' ELSE 'pending' END,
           billing_note = btrim(p_comment)
     WHERE id = v_pay.org_id;
  END IF;

  INSERT INTO public.push_outbox (user_id, title, body, url, tag)
  SELECT u.id,
         CASE WHEN p_approve THEN '✅ Pago aprobado' ELSE '⚠️ Pago pendiente' END,
         CASE WHEN p_approve THEN 'Tu suscripción está al día hasta el ' || to_char(v_end, 'DD/MM/YYYY')
              ELSE left(btrim(p_comment), 140) END,
         '/admin/organization', 'org_payment'
    FROM public.users u
   WHERE u.org_id = v_pay.org_id AND u.role = 'admin';
END;
$$;
REVOKE ALL ON FUNCTION public.review_org_payment(UUID, BOOLEAN, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.review_org_payment(UUID, BOOLEAN, TEXT) TO authenticated;

-- Diario: suscripciones vencidas → pago pendiente; aviso 3 días antes
CREATE OR REPLACE FUNCTION public.refresh_org_billing()
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_today DATE := (now() AT TIME ZONE 'America/Costa_Rica')::date;
BEGIN
  UPDATE public.organizations
     SET billing_status = 'pending', billing_note = 'Suscripción vencida'
   WHERE billing_status = 'approved' AND paid_until < v_today;

  INSERT INTO public.push_outbox (user_id, title, body, url, tag, dedupe_key)
  SELECT u.id, '⏰ Tu suscripción vence en 3 días',
         'Sube el comprobante de pago desde Mi gimnasio.',
         '/admin/organization', 'org_billing',
         'org:' || o.id || ':' || o.paid_until || ':' || u.id
    FROM public.organizations o
    JOIN public.users u ON u.org_id = o.id AND u.role = 'admin'
   WHERE o.paid_until = v_today + 3 AND o.billing_status = 'approved'
  ON CONFLICT (dedupe_key) DO NOTHING;
END;
$$;
REVOKE ALL ON FUNCTION public.refresh_org_billing() FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------
-- 10. Storage: comprobantes (privado) y logos (público)
-- ---------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('payment-receipts', 'payment-receipts', false, 5 * 1024 * 1024,
        ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
ON CONFLICT (id) DO UPDATE
  SET public = false, file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('org-logos', 'org-logos', true, 2 * 1024 * 1024,
        ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE
  SET public = true, file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS receipts_insert ON storage.objects;
DROP POLICY IF EXISTS receipts_select ON storage.objects;
CREATE POLICY receipts_insert ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'payment-receipts'
              AND public.is_admin()
              AND (storage.foldername(name))[1] = public.my_org_id()::text);
CREATE POLICY receipts_select ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'payment-receipts'
         AND (public.is_platform_admin()
              OR (public.is_admin()
                  AND (storage.foldername(name))[1] = public.my_org_id()::text)));

DROP POLICY IF EXISTS org_logos_insert ON storage.objects;
DROP POLICY IF EXISTS org_logos_update ON storage.objects;
DROP POLICY IF EXISTS org_logos_delete ON storage.objects;
CREATE POLICY org_logos_insert ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'org-logos' AND public.is_admin()
              AND (storage.foldername(name))[1] = public.my_org_id()::text);
CREATE POLICY org_logos_update ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'org-logos' AND public.is_admin()
         AND (storage.foldername(name))[1] = public.my_org_id()::text);
CREATE POLICY org_logos_delete ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'org-logos' AND public.is_admin()
         AND (storage.foldername(name))[1] = public.my_org_id()::text);

COMMIT;

-- Tarea diaria de cobro (8:05 Costa Rica)
DO $$
BEGIN
  PERFORM cron.unschedule('org-billing')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'org-billing');
  PERFORM cron.schedule('org-billing', '5 14 * * *', 'SELECT public.refresh_org_billing();');
END;
$$;
