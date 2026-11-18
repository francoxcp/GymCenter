-- =============================================================
-- Biblioteca de ejercicios con video/GIF e instrucciones
-- - Filas globales (org_id NULL): catálogo base de GYMLAB, solo
--   editable por el súper admin de la plataforma.
-- - Filas por organización: cada gimnasio/entrenador agrega las suyas
--   (p. ej. al subir un video propio) y solo las ve su organización.
-- Idempotente: se puede ejecutar varias veces.
-- =============================================================

CREATE TABLE IF NOT EXISTS public.exercise_library (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id        uuid REFERENCES public.organizations(id) ON DELETE CASCADE,
  name          text NOT NULL CHECK (char_length(btrim(name)) BETWEEN 2 AND 120),
  muscle_group  text NOT NULL DEFAULT 'General' CHECK (char_length(muscle_group) <= 40),
  default_sets  integer NOT NULL DEFAULT 3  CHECK (default_sets BETWEEN 1 AND 20),
  default_reps  integer NOT NULL DEFAULT 12 CHECK (default_reps BETWEEN 1 AND 200),
  default_rest  integer NOT NULL DEFAULT 60 CHECK (default_rest BETWEEN 0 AND 600),
  media_url     text CHECK (media_url IS NULL OR (media_url ~* '^https://' AND char_length(media_url) <= 500)),
  instructions  text CHECK (instructions IS NULL OR char_length(instructions) <= 4000),
  source        text CHECK (source IS NULL OR char_length(source) <= 30), -- 'gymlab', 'upload', 'exercisedb'
  created_by    uuid REFERENCES public.users(id) ON DELETE SET NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- Un nombre por organización (y uno por nombre en el catálogo global)
CREATE UNIQUE INDEX IF NOT EXISTS exercise_library_org_name_uidx
  ON public.exercise_library (
    COALESCE(org_id, '00000000-0000-0000-0000-000000000000'::uuid),
    lower(btrim(name))
  );
CREATE INDEX IF NOT EXISTS exercise_library_org_idx
  ON public.exercise_library (org_id);
CREATE INDEX IF NOT EXISTS exercise_library_created_by_idx
  ON public.exercise_library (created_by);

-- updated_at automático; autor, organización y fecha no se pueden cambiar
CREATE OR REPLACE FUNCTION public.exercise_library_touch()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at := now();
  IF auth.uid() IS NOT NULL THEN
    NEW.created_by := OLD.created_by;
    NEW.org_id     := OLD.org_id;
    NEW.created_at := OLD.created_at;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS exercise_library_touch ON public.exercise_library;
CREATE TRIGGER exercise_library_touch
  BEFORE UPDATE ON public.exercise_library
  FOR EACH ROW EXECUTE FUNCTION public.exercise_library_touch();

-- Al insertar: el autor y la organización los pone el servidor, no el cliente
CREATE OR REPLACE FUNCTION public.exercise_library_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    NEW.created_by := auth.uid();
    -- Solo el súper admin puede crear filas globales
    IF NOT public.is_platform_admin() THEN
      NEW.org_id := public.my_active_org_id();
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS exercise_library_guard ON public.exercise_library;
CREATE TRIGGER exercise_library_guard
  BEFORE INSERT ON public.exercise_library
  FOR EACH ROW EXECUTE FUNCTION public.exercise_library_guard();

-- ---------------- RLS ----------------
ALTER TABLE public.exercise_library ENABLE ROW LEVEL SECURITY;

-- Ver: catálogo global + el de mi organización
DROP POLICY IF EXISTS exercise_library_select ON public.exercise_library;
CREATE POLICY exercise_library_select ON public.exercise_library
  FOR SELECT TO authenticated
  USING (
    org_id IS NULL
    OR org_id = (SELECT public.my_active_org_id())
    OR (SELECT public.is_platform_admin())
  );

-- Crear: dueño o entrenador en su organización; súper admin en global
DROP POLICY IF EXISTS exercise_library_insert ON public.exercise_library;
CREATE POLICY exercise_library_insert ON public.exercise_library
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT public.is_platform_admin())
    OR (
      (SELECT public.is_staff())
      AND org_id IS NOT NULL
      AND org_id = (SELECT public.my_active_org_id())
    )
  );

-- Editar: el autor o el dueño de esa organización; súper admin todo
DROP POLICY IF EXISTS exercise_library_update ON public.exercise_library;
CREATE POLICY exercise_library_update ON public.exercise_library
  FOR UPDATE TO authenticated
  USING (
    (SELECT public.is_platform_admin())
    OR (
      org_id IS NOT NULL
      AND org_id = (SELECT public.my_active_org_id())
      AND (SELECT public.is_staff())
      AND (created_by = (SELECT auth.uid()) OR (SELECT public.is_admin()))
    )
  )
  WITH CHECK (
    (SELECT public.is_platform_admin())
    OR (
      org_id IS NOT NULL
      AND org_id = (SELECT public.my_active_org_id())
      AND (SELECT public.is_staff())
      AND (created_by = (SELECT auth.uid()) OR (SELECT public.is_admin()))
    )
  );

DROP POLICY IF EXISTS exercise_library_delete ON public.exercise_library;
CREATE POLICY exercise_library_delete ON public.exercise_library
  FOR DELETE TO authenticated
  USING (
    (SELECT public.is_platform_admin())
    OR (
      org_id IS NOT NULL
      AND org_id = (SELECT public.my_active_org_id())
      AND (SELECT public.is_staff())
      AND (created_by = (SELECT auth.uid()) OR (SELECT public.is_admin()))
    )
  );

REVOKE ALL ON public.exercise_library FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.exercise_library TO authenticated;

-- ---------------- Catálogo base (global) ----------------
-- Sin video todavía: se completa con media_url al importar un dataset
-- con licencia comercial o con los videos que suban los gimnasios.
INSERT INTO public.exercise_library
  (org_id, name, muscle_group, default_sets, default_reps, default_rest, source)
SELECT NULL, v.name, v.muscle, v.sets, v.reps, v.rest, 'gymlab'
FROM (VALUES
  ('Press de banca con barra','Pecho',3,10,90),
  ('Press inclinado con mancuernas','Pecho',3,10,90),
  ('Press declinado','Pecho',3,10,90),
  ('Aperturas con mancuernas','Pecho',3,12,60),
  ('Cruce de poleas','Pecho',3,12,60),
  ('Press en máquina (pecho)','Pecho',3,12,60),
  ('Fondos en paralelas','Pecho',3,10,60),
  ('Flexiones','Pecho',3,15,60),
  ('Dominadas','Espalda',3,8,90),
  ('Jalón al pecho','Espalda',3,10,60),
  ('Jalón abierto en pronación en polea alta','Espalda',3,12,90),
  ('Jalón cerrado neutro con inclinación en polea alta','Espalda',3,12,90),
  ('Jalón en supinación en polea alta','Espalda',3,12,90),
  ('Remo con barra','Espalda',3,10,90),
  ('Remo con mancuerna','Espalda',3,10,60),
  ('Remo sentado en polea','Espalda',3,12,60),
  ('Remo horizontal neutro en polea','Espalda',3,12,90),
  ('Remo horizontal cerrado neutro amplio en polea','Espalda',3,12,90),
  ('Remo horizontal en pronación en máquina','Espalda',3,12,90),
  ('Remo superior en pronación en polea','Espalda',3,15,90),
  ('Serratos inferiores con barra en polea','Espalda',3,12,90),
  ('Pullover en polea','Espalda',3,12,60),
  ('Peso muerto','Espalda',4,6,120),
  ('Hiperextensiones','Espalda',3,15,60),
  ('Sentadilla con barra','Piernas',4,8,120),
  ('Sentadilla goblet','Piernas',3,12,90),
  ('Prensa de piernas','Piernas',4,10,90),
  ('Zancadas con mancuernas','Piernas',3,10,60),
  ('Sentadilla búlgara','Piernas',3,10,90),
  ('Extensión de cuádriceps','Piernas',3,12,60),
  ('Curl femoral acostado','Piernas',3,12,60),
  ('Peso muerto rumano','Piernas',3,10,90),
  ('Elevación de talones (pantorrilla)','Piernas',3,15,60),
  ('Hip thrust con barra','Glúteos',4,10,90),
  ('Patada de glúteo en polea','Glúteos',3,15,60),
  ('Abducción en máquina','Glúteos',3,15,60),
  ('Puente de glúteo','Glúteos',3,15,60),
  ('Press militar con barra','Hombros',3,8,90),
  ('Press de hombro con mancuernas','Hombros',3,10,60),
  ('Elevaciones laterales','Hombros',3,15,60),
  ('Elevaciones frontales','Hombros',3,12,60),
  ('Pájaros (deltoides posterior)','Hombros',3,15,60),
  ('Face pull','Hombros',3,15,60),
  ('Encogimientos (trapecio)','Hombros',3,12,60),
  ('Curl con barra','Bíceps',3,10,60),
  ('Curl alterno con mancuernas','Bíceps',3,12,60),
  ('Curl martillo','Bíceps',3,12,60),
  ('Curl predicador','Bíceps',3,10,60),
  ('Curl en polea','Bíceps',3,12,60),
  ('Extensión de tríceps en polea','Tríceps',3,12,60),
  ('Press francés','Tríceps',3,10,60),
  ('Fondos en banco','Tríceps',3,12,60),
  ('Patada de tríceps','Tríceps',3,12,60),
  ('Press cerrado','Tríceps',3,10,90),
  ('Plancha (segundos)','Core',3,30,45),
  ('Crunch abdominal','Core',3,20,45),
  ('Elevación de piernas colgado','Core',3,12,60),
  ('Rueda abdominal','Core',3,10,60),
  ('Russian twist','Core',3,20,45),
  ('Plancha lateral (segundos)','Core',3,30,45),
  ('Caminadora (minutos)','Cardio',1,15,0),
  ('Bicicleta estática (minutos)','Cardio',1,15,0),
  ('Elíptica (minutos)','Cardio',1,15,0),
  ('Remo ergómetro (minutos)','Cardio',1,10,0),
  ('Saltar la cuerda','Cardio',3,60,45),
  ('Burpees','Cardio',3,12,60)
) AS v(name, muscle, sets, reps, rest)
WHERE NOT EXISTS (
  SELECT 1 FROM public.exercise_library l
  WHERE l.org_id IS NULL AND lower(btrim(l.name)) = lower(btrim(v.name))
);
