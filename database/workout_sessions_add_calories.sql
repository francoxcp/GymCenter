-- Agregar columna de calorías quemadas a workout_sessions
ALTER TABLE workout_sessions 
ADD COLUMN IF NOT EXISTS calories_burned INT DEFAULT 0;

-- Agregar comentario a la columna
COMMENT ON COLUMN workout_sessions.calories_burned IS 'Calorías quemadas durante la sesión (puede ser manual o calculada automáticamente)';

-- Índice para consultas de calorías por usuario y fecha
CREATE INDEX IF NOT EXISTS idx_workout_sessions_calories 
ON workout_sessions(user_id, completed_at, calories_burned);
