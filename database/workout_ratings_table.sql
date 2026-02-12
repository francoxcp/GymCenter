-- Tabla para almacenar ratings/valoraciones de workouts completados
CREATE TABLE IF NOT EXISTS workout_ratings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  session_id UUID REFERENCES workout_sessions(id) ON DELETE SET NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Un usuario solo puede dar un rating por sesión de workout
  UNIQUE(user_id, session_id)
);

-- Índices para mejorar rendimiento de consultas
CREATE INDEX IF NOT EXISTS idx_workout_ratings_user_id ON workout_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_ratings_workout_id ON workout_ratings(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_ratings_session_id ON workout_ratings(session_id);
CREATE INDEX IF NOT EXISTS idx_workout_ratings_created_at ON workout_ratings(created_at DESC);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_workout_ratings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_workout_ratings_updated_at
  BEFORE UPDATE ON workout_ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_ratings_updated_at();

-- RLS (Row Level Security) Policies
ALTER TABLE workout_ratings ENABLE ROW LEVEL SECURITY;

-- Policy: Los usuarios pueden ver sus propios ratings
CREATE POLICY "Users can view own workout ratings"
  ON workout_ratings
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Los usuarios pueden insertar sus propios ratings
CREATE POLICY "Users can insert own workout ratings"
  ON workout_ratings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Los usuarios pueden actualizar sus propios ratings
CREATE POLICY "Users can update own workout ratings"
  ON workout_ratings
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Los usuarios pueden eliminar sus propios ratings
CREATE POLICY "Users can delete own workout ratings"
  ON workout_ratings
  FOR DELETE
  USING (auth.uid() = user_id);

-- Policy: Los admins pueden ver todos los ratings
CREATE POLICY "Admins can view all workout ratings"
  ON workout_ratings
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Comentarios para documentación
COMMENT ON TABLE workout_ratings IS 'Almacena las valoraciones de los usuarios sobre workouts completados';
COMMENT ON COLUMN workout_ratings.rating IS 'Valoración de 1 a 5 estrellas';
COMMENT ON COLUMN workout_ratings.comment IS 'Comentario opcional del usuario sobre el workout';
COMMENT ON COLUMN workout_ratings.session_id IS 'Referencia a la sesión específica de workout completada';
