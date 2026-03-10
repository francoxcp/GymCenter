-- ============================================================
-- Migración: Añadir campos de fitness a la tabla users
-- Ejecutar en Supabase SQL Editor
-- ============================================================

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS age        integer        CHECK (age BETWEEN 12 AND 120),
  ADD COLUMN IF NOT EXISTS weight_kg  numeric(5,2)   CHECK (weight_kg BETWEEN 20 AND 500),
  ADD COLUMN IF NOT EXISTS height_cm  integer        CHECK (height_cm BETWEEN 100 AND 300),
  ADD COLUMN IF NOT EXISTS sex        text           CHECK (sex IN ('male', 'female', 'other'));

-- Comentarios para documentación
COMMENT ON COLUMN users.age       IS 'Edad en años — usada para el cálculo BMR (Harris-Benedict)';
COMMENT ON COLUMN users.weight_kg IS 'Peso corporal en kilogramos — fuente primaria para cálculo de calorías';
COMMENT ON COLUMN users.height_cm IS 'Altura en centímetros — componente del cálculo BMR';
COMMENT ON COLUMN users.sex       IS 'Sexo biológico: male | female | other — ajusta la ecuación BMR';
