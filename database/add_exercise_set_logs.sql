-- Tabla para registrar el peso y reps usados por serie en cada entrenamiento
-- Ejecutar en el SQL Editor de Supabase

CREATE TABLE IF NOT EXISTS exercise_set_logs (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_id  TEXT NOT NULL,
  exercise_index INTEGER NOT NULL,
  set_index   INTEGER NOT NULL,
  exercise_name TEXT NOT NULL DEFAULT '',
  weight_kg   DOUBLE PRECISION,
  reps        INTEGER,
  logged_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice para consultas rápidas por usuario + workout
CREATE INDEX IF NOT EXISTS idx_exercise_set_logs_user_workout
  ON exercise_set_logs (user_id, workout_id, logged_at DESC);

-- RLS: cada usuario solo ve sus propios registros
ALTER TABLE exercise_set_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_own_exercise_logs" ON exercise_set_logs;
CREATE POLICY "users_own_exercise_logs"
  ON exercise_set_logs
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
