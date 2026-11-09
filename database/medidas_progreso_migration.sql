-- =====================================================================
-- Medidas corporales completas, objetivo del socio visible para su
-- entrenador y eliminación del "nivel" del usuario.
-- Idempotente.
-- =====================================================================
BEGIN;

-- ---------------------------------------------------------------------
-- 1. Objetivo del socio (antes solo quedaba en sus preferencias locales)
-- ---------------------------------------------------------------------
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS goal TEXT
  CHECK (goal IS NULL OR char_length(goal) <= 60);
UPDATE public.users u
   SET goal = left(p.onboarding_data->>'goal', 60)
  FROM public.user_preferences p
 WHERE p.user_id = u.id AND u.goal IS NULL
   AND nullif(p.onboarding_data->>'goal', '') IS NOT NULL;

-- ---------------------------------------------------------------------
-- 2. Sin nivel del usuario (Principiante/Intermedio/Avanzado)
--    El nivel de las RUTINAS (dificultad) se mantiene.
-- ---------------------------------------------------------------------
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
  IF v_org IS NOT NULL AND NOT COALESCE(public.org_has_room(v_org), true) THEN
    v_trainer := NULL;
    v_org := NULL;
  END IF;

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
ALTER TABLE public.users DROP COLUMN IF EXISTS level;

-- ---------------------------------------------------------------------
-- 3. Medidas corporales completas
-- ---------------------------------------------------------------------
ALTER TABLE public.body_measurements
  ADD COLUMN IF NOT EXISTS body_fat     NUMERIC(4,1) CHECK (body_fat IS NULL OR body_fat BETWEEN 2 AND 70),
  ADD COLUMN IF NOT EXISTS neck         NUMERIC(5,1) CHECK (neck IS NULL OR neck BETWEEN 5 AND 300),
  ADD COLUMN IF NOT EXISTS forearm      NUMERIC(5,1) CHECK (forearm IS NULL OR forearm BETWEEN 5 AND 300),
  ADD COLUMN IF NOT EXISTS calf         NUMERIC(5,1) CHECK (calf IS NULL OR calf BETWEEN 5 AND 300),
  ADD COLUMN IF NOT EXISTS biceps_left  NUMERIC(5,1) CHECK (biceps_left IS NULL OR biceps_left BETWEEN 5 AND 300),
  ADD COLUMN IF NOT EXISTS biceps_right NUMERIC(5,1) CHECK (biceps_right IS NULL OR biceps_right BETWEEN 5 AND 300),
  ADD COLUMN IF NOT EXISTS thigh_left   NUMERIC(5,1) CHECK (thigh_left IS NULL OR thigh_left BETWEEN 5 AND 300),
  ADD COLUMN IF NOT EXISTS thigh_right  NUMERIC(5,1) CHECK (thigh_right IS NULL OR thigh_right BETWEEN 5 AND 300),
  ADD COLUMN IF NOT EXISTS recorded_by  UUID REFERENCES public.users(id) ON DELETE SET NULL;

-- Las medidas viejas (un solo brazo/muslo) pasan a izquierdo y derecho
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_schema = 'public' AND table_name = 'body_measurements'
                AND column_name = 'biceps') THEN
    UPDATE public.body_measurements
       SET biceps_left  = COALESCE(biceps_left, biceps),
           biceps_right = COALESCE(biceps_right, biceps),
           thigh_left   = COALESCE(thigh_left, thighs),
           thigh_right  = COALESCE(thigh_right, thighs);
    ALTER TABLE public.body_measurements DROP COLUMN biceps;
    ALTER TABLE public.body_measurements DROP COLUMN thighs;
  END IF;
END $$;
-- La altura vive en el perfil del socio: se copia la última medida si el
-- perfil no la tiene, y luego se quita de las medidas
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_schema = 'public' AND table_name = 'body_measurements'
                AND column_name = 'height') THEN
    UPDATE public.users u
       SET height_cm = round(b.height)::int
      FROM (SELECT DISTINCT ON (user_id) user_id, height
              FROM public.body_measurements
             WHERE height BETWEEN 100 AND 250
             ORDER BY user_id, date DESC) b
     WHERE b.user_id = u.id AND u.height_cm IS NULL;
    ALTER TABLE public.body_measurements DROP COLUMN height;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_body_measurements_user_date
  ON public.body_measurements (user_id, date DESC);

-- El socio y su entrenador (o el dueño) registran, corrigen y borran
DROP POLICY IF EXISTS bm_insert ON public.body_measurements;
DROP POLICY IF EXISTS bm_update ON public.body_measurements;
DROP POLICY IF EXISTS bm_delete ON public.body_measurements;
CREATE POLICY bm_insert ON public.body_measurements FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() OR public.can_manage_user(user_id));
CREATE POLICY bm_update ON public.body_measurements FOR UPDATE TO authenticated
  USING (user_id = auth.uid() OR public.can_manage_user(user_id))
  WITH CHECK (user_id = auth.uid() OR public.can_manage_user(user_id));
CREATE POLICY bm_delete ON public.body_measurements FOR DELETE TO authenticated
  USING (user_id = auth.uid() OR public.can_manage_user(user_id));

-- Quién registró lo pone el servidor; al corregir no cambia ni de socio
-- ni de autor
CREATE OR REPLACE FUNCTION public.body_measurements_guard()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF auth.uid() IS NOT NULL THEN NEW.recorded_by := auth.uid(); END IF;
  ELSE
    NEW.user_id := OLD.user_id;
    NEW.recorded_by := OLD.recorded_by;
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.body_measurements_guard() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS trg_body_measurements_guard ON public.body_measurements;
CREATE TRIGGER trg_body_measurements_guard
  BEFORE INSERT OR UPDATE ON public.body_measurements
  FOR EACH ROW EXECUTE FUNCTION public.body_measurements_guard();

COMMIT;
