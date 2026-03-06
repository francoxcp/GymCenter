-- ============================================
-- Migración: agregar columna category a workouts
-- Fecha: 2026-03-05
-- ============================================

ALTER TABLE workouts
  ADD COLUMN IF NOT EXISTS category TEXT
    CHECK (category IN ('Pecho', 'Espalda', 'Pierna', 'Cardio', 'Funcional'));

-- Actualizar rutinas existentes si el nombre da pistas (opcional, ajustar según necesidad)
-- UPDATE workouts SET category = 'Pecho'    WHERE LOWER(name) LIKE '%pecho%';
-- UPDATE workouts SET category = 'Espalda'  WHERE LOWER(name) LIKE '%espalda%';
-- UPDATE workouts SET category = 'Pierna'   WHERE LOWER(name) LIKE '%pierna%' OR LOWER(name) LIKE '%leg%';
-- UPDATE workouts SET category = 'Cardio'   WHERE LOWER(name) LIKE '%cardio%' OR LOWER(name) LIKE '%hiit%';
-- UPDATE workouts SET category = 'Funcional' WHERE LOWER(name) LIKE '%funcional%';
