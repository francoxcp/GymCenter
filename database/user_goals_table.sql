-- Tabla para gestionar metas de usuarios
CREATE TABLE user_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  goal_type VARCHAR(20) NOT NULL CHECK (goal_type IN ('weight', 'calories', 'workouts')),
  title VARCHAR(100) NOT NULL,
  target_value DECIMAL(10, 2) NOT NULL,
  current_value DECIMAL(10, 2) DEFAULT 0,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejor rendimiento
CREATE INDEX idx_user_goals_user_id ON user_goals(user_id);
CREATE INDEX idx_user_goals_active ON user_goals(is_active);
CREATE INDEX idx_user_goals_dates ON user_goals(start_date, end_date);

-- RLS Policies
ALTER TABLE user_goals ENABLE ROW LEVEL SECURITY;

-- Policy: Los usuarios solo pueden ver sus propias metas
CREATE POLICY "Users can view their own goals"
ON user_goals FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Los usuarios pueden crear sus propias metas
CREATE POLICY "Users can create their own goals"
ON user_goals FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Los usuarios pueden actualizar sus propias metas
CREATE POLICY "Users can update their own goals"
ON user_goals FOR UPDATE
USING (auth.uid() = user_id);

-- Policy: Los usuarios pueden eliminar sus propias metas
CREATE POLICY "Users can delete their own goals"
ON user_goals FOR DELETE
USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_user_goals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_goals_updated_at
BEFORE UPDATE ON user_goals
FOR EACH ROW
EXECUTE FUNCTION update_user_goals_updated_at();
