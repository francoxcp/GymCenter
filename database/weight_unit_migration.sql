-- =============================================================
-- Unidad de peso por ejercicio (lbs o kg)
-- El peso se sigue guardando en kg (weight_kg); weight_unit solo indica
-- en qué unidad se muestra y se anota (mancuernas en lbs, máquinas en kg).
-- Los ejercicios existentes quedan en 'lbs', como se veían hasta ahora.
-- Idempotente: se puede ejecutar varias veces.
-- =============================================================

ALTER TABLE public.exercises
  ADD COLUMN IF NOT EXISTS weight_unit text NOT NULL DEFAULT 'lbs';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'exercises_weight_unit_chk'
      AND conrelid = 'public.exercises'::regclass
  ) THEN
    ALTER TABLE public.exercises
      ADD CONSTRAINT exercises_weight_unit_chk
      CHECK (weight_unit IN ('lbs', 'kg'));
  END IF;
END $$;

-- Las políticas RLS de exercises no cambian: la columna nueva se rige por
-- las mismas reglas que el resto del ejercicio.
