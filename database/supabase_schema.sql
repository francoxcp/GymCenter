-- ============================================
-- TABLAS PRINCIPALES - SUPABASE
-- Chamos Fitness Center
-- ============================================
-- Ejecutar ANTES de las políticas RLS

-- ============================================
-- EXTENSIONES NECESARIAS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. TABLA: meal_plans
-- ============================================
CREATE TABLE meal_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  calories INT,
  protein_g INT,
  carbs_g INT,
  fats_g INT,
  meals JSONB, -- Array de comidas con detalles
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 2. TABLA: workouts
-- ============================================
CREATE TABLE workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  duration INT NOT NULL, -- en minutos
  exercise_count INT DEFAULT 0,
  level TEXT CHECK (level IN ('Principiante', 'Intermedio', 'Avanzado')),
  image_url TEXT,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 3. TABLA: users (vinculada con auth.users)
-- ============================================
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  photo_url TEXT,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
  level TEXT DEFAULT 'Principiante' CHECK (level IN ('Principiante', 'Intermedio', 'Avanzado')),
  active_days INT DEFAULT 0,
  completed_workouts INT DEFAULT 0,
  assigned_workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
  assigned_meal_plan_id UUID REFERENCES meal_plans(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 4. TABLA: exercises
-- ============================================
CREATE TABLE exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  sets INT NOT NULL,
  reps TEXT NOT NULL, -- Puede ser "12" o "12-15" o "Max"
  rest_time INT NOT NULL, -- en segundos
  video_url TEXT,
  muscle_group TEXT,
  instructions TEXT,
  order_index INT NOT NULL DEFAULT 0, -- Para mantener orden
  weight_kg DECIMAL(5,2), -- Peso sugerido (opcional)
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 5. TABLA: workout_sessions (historial)
-- ============================================
CREATE TABLE workout_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  duration_minutes INT NOT NULL,
  calories_burned INT,
  total_volume_kg DECIMAL(10,2), -- Peso total levantado
  exercises_completed JSONB, -- Array con detalles de cada ejercicio
  completed_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 6. TABLA: body_measurements (medidas corporales)
-- ============================================
CREATE TABLE body_measurements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date TIMESTAMP NOT NULL DEFAULT NOW(),
  weight DECIMAL(5,2), -- kg
  height DECIMAL(5,2), -- cm
  chest DECIMAL(5,2), -- cm
  waist DECIMAL(5,2), -- cm
  hips DECIMAL(5,2), -- cm
  biceps DECIMAL(5,2), -- cm
  thighs DECIMAL(5,2), -- cm
  photo_url TEXT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 7. TABLA: user_preferences (configuración y onboarding)
-- ============================================
CREATE TABLE user_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  onboarding_data JSONB, -- Datos del onboarding (goal, weight inicial, etc)
  
  -- Notificaciones
  notifications_enabled BOOLEAN DEFAULT TRUE,
  workout_reminders BOOLEAN DEFAULT TRUE,
  achievement_alerts BOOLEAN DEFAULT TRUE,
  reminder_time TIME DEFAULT '08:00:00',
  
  -- Preferencias
  theme TEXT DEFAULT 'dark' CHECK (theme IN ('light', 'dark')),
  units TEXT DEFAULT 'metric' CHECK (units IN ('metric', 'imperial')),
  language TEXT DEFAULT 'es' CHECK (language IN ('es', 'en')),
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 8. TABLA: achievements (logros)
-- ============================================
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL, -- 'first_week', 'ten_workouts', etc.
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  points INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 9. TABLA: user_achievements (logros desbloqueados)
-- ============================================
CREATE TABLE user_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- ============================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_assigned_workout ON users(assigned_workout_id);
CREATE INDEX IF NOT EXISTS idx_exercises_workout_id ON exercises(workout_id);
CREATE INDEX IF NOT EXISTS idx_exercises_order ON exercises(workout_id, order_index);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_workout_id ON workout_sessions(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_completed_at ON workout_sessions(completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_body_measurements_user_id ON body_measurements(user_id);
CREATE INDEX IF NOT EXISTS idx_body_measurements_date ON body_measurements(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked_at ON user_achievements(user_id, unlocked_at DESC);

-- ============================================
-- TRIGGER: Actualizar updated_at automáticamente
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workouts_updated_at
  BEFORE UPDATE ON workouts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meal_plans_updated_at
  BEFORE UPDATE ON meal_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNCIÓN: Crear usuario en tabla users después de registro
-- ============================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Crear usuario en tabla public.users
  INSERT INTO public.users (id, email, name, role, level)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'Usuario Nuevo'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
    'Principiante'
  );
  
  -- Crear preferencias por defecto
  INSERT INTO public.user_preferences (user_id)
  VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear usuario automáticamente al registrarse
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ============================================
-- DATOS DE PRUEBA (SEED)
-- ============================================

-- Insertar planes de comida de ejemplo
INSERT INTO meal_plans (name, description, calories, protein_g, carbs_g, fats_g, meals) VALUES
(
  'Plan Hipertrofia',
  'Plan alto en proteínas para ganancia muscular',
  2800,
  180,
  320,
  80,
  '[
    {"name": "Desayuno", "time": "08:00", "foods": ["Avena", "Claras de huevo", "Plátano"]},
    {"name": "Snack AM", "time": "11:00", "foods": ["Batido de proteína", "Almendras"]},
    {"name": "Almuerzo", "time": "14:00", "foods": ["Pollo", "Arroz integral", "Brócoli"]},
    {"name": "Snack PM", "time": "17:00", "foods": ["Atún", "Pan integral"]},
    {"name": "Cena", "time": "20:00", "foods": ["Salmón", "Quinoa", "Espárragos"]}
  ]'::jsonb
),
(
  'Plan Definición',
  'Plan bajo en carbohidratos para pérdida de grasa',
  2000,
  160,
  150,
  70,
  '[
    {"name": "Desayuno", "time": "08:00", "foods": ["Huevos revueltos", "Aguacate"]},
    {"name": "Snack AM", "time": "11:00", "foods": ["Yogurt griego", "Nueces"]},
    {"name": "Almuerzo", "time": "14:00", "foods": ["Pavo", "Ensalada verde", "Aceite de oliva"]},
    {"name": "Snack PM", "time": "17:00", "foods": ["Batido de proteína"]},
    {"name": "Cena", "time": "20:00", "foods": ["Pescado blanco", "Vegetales al vapor"]}
  ]'::jsonb
);

-- Insertar rutinas de ejemplo
INSERT INTO workouts (name, duration, level, image_url, description) VALUES
('Full Body Beginner', 45, 'Principiante', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48', 'Rutina completa para principiantes'),
('Upper Body Strength', 60, 'Intermedio', 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e', 'Enfocada en tren superior'),
('HIIT Cardio', 30, 'Avanzado', 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438', 'Alta intensidad cardiovascular');

-- Insertar ejercicios para la primera rutina
INSERT INTO exercises (workout_id, name, sets, reps, rest_time, muscle_group, instructions, order_index) VALUES
(
  (SELECT id FROM workouts WHERE name = 'Full Body Beginner'),
  'Sentadilla',
  3,
  '12-15',
  60,
  'Piernas',
  '1. Pies al ancho de hombros\n2. Baja manteniendo la espalda recta\n3. Sube explosivamente',
  1
),
(
  (SELECT id FROM workouts WHERE name = 'Full Body Beginner'),
  'Press de Banca',
  3,
  '10-12',
  90,
  'Pecho',
  '1. Acuéstate en el banco\n2. Baja la barra controladamente\n3. Empuja hacia arriba',
  2
),
(
  (SELECT id FROM workouts WHERE name = 'Full Body Beginner'),
  'Peso Muerto',
  3,
  '8-10',
  120,
  'Espalda',
  '1. Mantén la espalda recta\n2. Levanta la barra pegada al cuerpo\n3. Completa la extensión de cadera',
  3
);

-- Insertar logros de ejemplo
INSERT INTO achievements (code, name, description, icon, points) VALUES
('first_workout', 'Primer Entrenamiento', 'Completaste tu primer entrenamiento', '🏋️', 10),
('first_week', 'Primera Semana', 'Completaste 7 días seguidos', '🔥', 50),
('ten_workouts', '10 Entrenamientos', 'Completaste 10 entrenamientos', '💪', 100),
('streak_7', 'Racha de 7 días', 'Mantuviste una racha de 7 días', '⭐', 75),
('streak_30', 'Racha de 30 días', 'Mantuviste una racha de 30 días', '🏆', 300),
('weight_loss_5kg', 'Pérdida de 5kg', 'Perdiste 5kg desde el inicio', '📉', 150);

-- ============================================
-- TRIGGERS AUTOMÁTICOS
-- ============================================

-- Trigger para actualizar exercise_count automáticamente
CREATE OR REPLACE FUNCTION update_workout_exercise_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    UPDATE workouts
    SET exercise_count = (
      SELECT COUNT(*) FROM exercises WHERE workout_id = OLD.workout_id
    )
    WHERE id = OLD.workout_id;
    RETURN OLD;
  ELSE
    UPDATE workouts
    SET exercise_count = (
      SELECT COUNT(*) FROM exercises WHERE workout_id = NEW.workout_id
    )
    WHERE id = NEW.workout_id;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_exercise_count
AFTER INSERT OR DELETE ON exercises
FOR EACH ROW
EXECUTE FUNCTION update_workout_exercise_count();

-- ============================================
-- NOTA: El contador completed_workouts se actualiza desde la app
-- No usamos trigger automático para evitar inconsistencias
-- ============================================

-- Trigger DESHABILITADO - La app maneja este contador manualmente
-- CREATE OR REPLACE FUNCTION update_user_completed_workouts()
-- RETURNS TRIGGER AS $$
-- BEGIN
--   UPDATE users
--   SET completed_workouts = completed_workouts + 1
--   WHERE id = NEW.user_id;
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_update_completed_workouts
-- AFTER INSERT ON workout_sessions
-- FOR EACH ROW
-- EXECUTE FUNCTION update_user_completed_workouts();

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Ejecutar para verificar que todo está OK:
-- SELECT * FROM meal_plans;
-- SELECT * FROM workouts;
-- SELECT * FROM exercises;
-- SELECT * FROM achievements;
