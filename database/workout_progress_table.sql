-- Tabla para guardar progreso incompleto de entrenamientos
CREATE TABLE IF NOT EXISTS workout_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  exercise_index INTEGER NOT NULL DEFAULT 0,
  completed_sets JSONB NOT NULL DEFAULT '[]'::jsonb,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Solo 1 progreso por usuario
  CONSTRAINT unique_user_progress UNIQUE (user_id)
);

-- Índices para mejorar performance
CREATE INDEX IF NOT EXISTS idx_workout_progress_user_id ON workout_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_progress_updated_at ON workout_progress(updated_at);

-- RLS Policies
ALTER TABLE workout_progress ENABLE ROW LEVEL SECURITY;

-- Los usuarios solo pueden ver/editar su propio progreso
CREATE POLICY "Users can view their own workout progress"
  ON workout_progress
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workout progress"
  ON workout_progress
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workout progress"
  ON workout_progress
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own workout progress"
  ON workout_progress
  FOR DELETE
  USING (auth.uid() = user_id);

-- Los admins pueden ver todo
CREATE POLICY "Admins can view all workout progress"
  ON workout_progress
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_workout_progress_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_workout_progress_updated_at
  BEFORE UPDATE ON workout_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_progress_updated_at();

-- Función para limpiar progresos antiguos (>24 horas)
CREATE OR REPLACE FUNCTION cleanup_old_workout_progress()
RETURNS void AS $$
BEGIN
  DELETE FROM workout_progress
  WHERE updated_at < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- Comentarios
COMMENT ON TABLE workout_progress IS 'Almacena el progreso incompleto de entrenamientos para permitir que los usuarios continúen desde donde lo dejaron';
COMMENT ON COLUMN workout_progress.exercise_index IS 'Índice del ejercicio actual (0-based)';
COMMENT ON COLUMN workout_progress.completed_sets IS 'Array de arrays booleanos indicando qué series están completadas. Ejemplo: [[true,false,false], [true,true,false]]';
