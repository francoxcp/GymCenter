-- ============================================
-- TABLA: exercise_set_logs
-- Historial de pesos usados por serie/ejercicio
-- Ejecutar en Supabase SQL Editor
-- ============================================

CREATE TABLE IF NOT EXISTS exercise_set_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  exercise_index INT NOT NULL,       -- índice del ejercicio dentro de la rutina
  set_index INT NOT NULL,            -- índice de la serie (0-based)
  exercise_name TEXT,                -- nombre del ejercicio (referencia)
  weight_kg DECIMAL(6,2),            -- peso en kg (almacenado internamente)
  reps INT,                          -- repeticiones del ejercicio
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para queries frecuentes
CREATE INDEX IF NOT EXISTS idx_exercise_set_logs_user_workout
  ON exercise_set_logs(user_id, workout_id);

CREATE INDEX IF NOT EXISTS idx_exercise_set_logs_logged_at
  ON exercise_set_logs(user_id, workout_id, logged_at DESC);

CREATE INDEX IF NOT EXISTS idx_exercise_set_logs_exercise
  ON exercise_set_logs(user_id, workout_id, exercise_index, logged_at DESC);

-- Row Level Security
ALTER TABLE exercise_set_logs ENABLE ROW LEVEL SECURITY;

-- Usuario solo ve sus propios registros
DROP POLICY IF EXISTS "exercise_set_logs_select" ON exercise_set_logs;
CREATE POLICY "exercise_set_logs_select"
  ON exercise_set_logs FOR SELECT
  USING (auth.uid() = user_id);

-- Usuario solo inserta sus propios registros
DROP POLICY IF EXISTS "exercise_set_logs_insert" ON exercise_set_logs;
CREATE POLICY "exercise_set_logs_insert"
  ON exercise_set_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Usuario puede eliminar sus propios registros (limpieza)
DROP POLICY IF EXISTS "exercise_set_logs_delete" ON exercise_set_logs;
CREATE POLICY "exercise_set_logs_delete"
  ON exercise_set_logs FOR DELETE
  USING (auth.uid() = user_id);

-- Admin puede ver todos los registros
DROP POLICY IF EXISTS "exercise_set_logs_admin_select" ON exercise_set_logs;
CREATE POLICY "exercise_set_logs_admin_select"
  ON exercise_set_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid() AND users.role = 'admin'
    )
  );
