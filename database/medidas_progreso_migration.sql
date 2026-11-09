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
   SET goal = p.onboarding_data->>'goal'
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
  ADD COLUMN IF NOT EXISTS neck         NUMERIC(5,1),
  ADD COLUMN IF NOT EXISTS forearm      NUMERIC(5,1),
  ADD COLUMN IF NOT EXISTS calf         NUMERIC(5,1),
  ADD COLUMN IF NOT EXISTS biceps_left  NUMERIC(5,1),
  ADD COLUMN IF NOT EXISTS biceps_right NUMERIC(5,1),
  ADD COLUMN IF NOT EXISTS thigh_left   NUMERIC(5,1),
  ADD COLUMN IF NOT EXISTS thigh_right  NUMERIC(5,1),
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
-- La altura vive en el perfil del socio
ALTER TABLE public.body_measurements DROP COLUMN IF EXISTS height;

CREATE INDEX IF NOT EXISTS idx_body_measurements_user_date
  ON public.body_measurements (user_id, date DESC);

-- El socio y su entrenador (o el dueño) registran, corrigen y borran
DROP POLICY IF EXISTS bm_insert ON public.body_measurements;
DROP POLICY IF EXISTS bm_update ON public.body_measurements;
DROP POLICY IF EXISTS bm_delete ON public.body_measurements;
CREATE POLICY bm_insert ON public.body_measurements FOR INSERT TO authenticated
  WITH CHECK ((user_id = auth.uid() OR public.can_manage_user(user_id))
              AND (recorded_by IS NULL OR recorded_by = auth.uid()));
CREATE POLICY bm_update ON public.body_measurements FOR UPDATE TO authenticated
  USING (user_id = auth.uid() OR public.can_manage_user(user_id))
  WITH CHECK (user_id = auth.uid() OR public.can_manage_user(user_id));
CREATE POLICY bm_delete ON public.body_measurements FOR DELETE TO authenticated
  USING (user_id = auth.uid() OR public.can_manage_user(user_id));

COMMIT;
