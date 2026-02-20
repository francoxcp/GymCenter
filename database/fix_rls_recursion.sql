-- ============================================
-- FIX: Solución a recursión infinita en políticas RLS
-- Ejecuta este script en Supabase SQL Editor
-- ============================================

-- PASO 1: Eliminar TODAS las políticas existentes que causan recursión
DROP POLICY IF EXISTS "users_select_own" ON users;
DROP POLICY IF EXISTS "users_select_all" ON users;
DROP POLICY IF EXISTS "admins_select_all_users" ON users;
DROP POLICY IF EXISTS "users_update_own" ON users;
DROP POLICY IF EXISTS "admins_update_all_users" ON users;
DROP POLICY IF EXISTS "admins_update_users" ON users;
DROP POLICY IF EXISTS "users_insert_own" ON users;
DROP POLICY IF EXISTS "admins_insert_users" ON users;
DROP POLICY IF EXISTS "users_delete_own" ON users;
DROP POLICY IF EXISTS "users_select_policy" ON users;
DROP POLICY IF EXISTS "users_update_policy" ON users;
DROP POLICY IF EXISTS "users_insert_policy" ON users;
DROP POLICY IF EXISTS "users_delete_policy" ON users;

DROP POLICY IF EXISTS "admins_insert_workouts" ON workouts;
DROP POLICY IF EXISTS "admins_update_workouts" ON workouts;
DROP POLICY IF EXISTS "admins_delete_workouts" ON workouts;

-- PASO 2: Crear una función helper para verificar si el usuario es admin
-- Esta función NO causa recursión porque usa SECURITY DEFINER
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM users
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$;

-- PASO 3: Crear nuevas políticas SIN recursión usando la función helper

-- ============================================
-- POLÍTICAS PARA TABLA: users
-- ============================================

-- SELECT: Los admins ven todos, los usuarios solo su perfil
CREATE POLICY "users_select_policy"
  ON users
  FOR SELECT
  USING (
    is_admin() OR id = auth.uid()
  );

-- UPDATE: Los admins actualizan cualquiera, los usuarios solo su perfil
CREATE POLICY "users_update_policy"
  ON users
  FOR UPDATE
  USING (
    is_admin() OR id = auth.uid()
  )
  WITH CHECK (
    is_admin() OR id = auth.uid()
  );

-- INSERT: Permitir inserción durante registro (el trigger handle_new_user lo usa)
CREATE POLICY "users_insert_policy"
  ON users
  FOR INSERT
  WITH CHECK (
    id = auth.uid()
  );

-- DELETE: Solo admins pueden eliminar usuarios
CREATE POLICY "users_delete_policy"
  ON users
  FOR DELETE
  USING (
    is_admin()
  );

-- ============================================
-- POLÍTICAS PARA TABLA: workouts
-- ============================================

-- Eliminar políticas existentes de workouts que causan recursión
DROP POLICY IF EXISTS "workouts_select_all" ON workouts;
DROP POLICY IF EXISTS "workouts_insert_admin" ON workouts;
DROP POLICY IF EXISTS "workouts_update_admin" ON workouts;
DROP POLICY IF EXISTS "workouts_delete_admin" ON workouts;

-- SELECT: Todos pueden ver workouts
CREATE POLICY "workouts_select_all"
  ON workouts
  FOR SELECT
  USING (true);

-- INSERT: Solo admins
CREATE POLICY "workouts_insert_admin"
  ON workouts
  FOR INSERT
  WITH CHECK (
    is_admin()
  );

-- UPDATE: Solo admins
CREATE POLICY "workouts_update_admin"
  ON workouts
  FOR UPDATE
  USING (
    is_admin()
  )
  WITH CHECK (
    is_admin()
  );

-- DELETE: Solo admins
CREATE POLICY "workouts_delete_admin"
  ON workouts
  FOR DELETE
  USING (
    is_admin()
  );

-- ============================================
-- POLÍTICAS PARA TABLA: exercises
-- ============================================

DROP POLICY IF EXISTS "exercises_select_all" ON exercises;
DROP POLICY IF EXISTS "admins_insert_exercises" ON exercises;
DROP POLICY IF EXISTS "admins_update_exercises" ON exercises;
DROP POLICY IF EXISTS "admins_delete_exercises" ON exercises;
DROP POLICY IF EXISTS "exercises_insert_admin" ON exercises;
DROP POLICY IF EXISTS "exercises_update_admin" ON exercises;
DROP POLICY IF EXISTS "exercises_delete_admin" ON exercises;

-- SELECT: Todos pueden ver ejercicios
CREATE POLICY "exercises_select_all"
  ON exercises
  FOR SELECT
  USING (true);

-- INSERT: Solo admins
CREATE POLICY "exercises_insert_admin"
  ON exercises
  FOR INSERT
  WITH CHECK (
    is_admin()
  );

-- UPDATE: Solo admins
CREATE POLICY "exercises_update_admin"
  ON exercises
  FOR UPDATE
  USING (
    is_admin()
  )
  WITH CHECK (
    is_admin()
  );

-- DELETE: Solo admins
CREATE POLICY "exercises_delete_admin"
  ON exercises
  FOR DELETE
  USING (
    is_admin()
  );

-- ============================================
-- POLÍTICAS PARA TABLA: meal_plans
-- ============================================

DROP POLICY IF EXISTS "meal_plans_select_all" ON meal_plans;
DROP POLICY IF EXISTS "meal_plans_insert_admin" ON meal_plans;
DROP POLICY IF EXISTS "meal_plans_update_admin" ON meal_plans;
DROP POLICY IF EXISTS "meal_plans_delete_admin" ON meal_plans;
DROP POLICY IF EXISTS "admins_insert_meal_plans" ON meal_plans;
DROP POLICY IF EXISTS "admins_update_meal_plans" ON meal_plans;
DROP POLICY IF EXISTS "admins_delete_meal_plans" ON meal_plans;

-- SELECT: Todos pueden ver planes de comida
CREATE POLICY "meal_plans_select_all"
  ON meal_plans
  FOR SELECT
  USING (true);

-- INSERT: Solo admins
CREATE POLICY "meal_plans_insert_admin"
  ON meal_plans
  FOR INSERT
  WITH CHECK (
    is_admin()
  );

-- UPDATE: Solo admins
CREATE POLICY "meal_plans_update_admin"
  ON meal_plans
  FOR UPDATE
  USING (
    is_admin()
  )
  WITH CHECK (
    is_admin()
  );

-- DELETE: Solo admins
CREATE POLICY "meal_plans_delete_admin"
  ON meal_plans
  FOR DELETE
  USING (
    is_admin()
  );

-- ============================================
-- Verificar que RLS está habilitado en todas las tablas
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;

-- ============================================
-- TABLAS ADICIONALES REQUERIDAS POR LA APP
-- ============================================

-- ============================================
-- TABLA: workout_progress (progreso incompleto de entrenamientos)
-- ============================================
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

-- Índices
CREATE INDEX IF NOT EXISTS idx_workout_progress_user_id ON workout_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_progress_updated_at ON workout_progress(updated_at);

-- RLS Policies
ALTER TABLE workout_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own workout progress" ON workout_progress;
DROP POLICY IF EXISTS "Users can insert their own workout progress" ON workout_progress;
DROP POLICY IF EXISTS "workout_progress_select_policy" ON workout_progress;
DROP POLICY IF EXISTS "workout_progress_insert_policy" ON workout_progress;
DROP POLICY IF EXISTS "workout_progress_update_policy" ON workout_progress;
DROP POLICY IF EXISTS "workout_progress_delete_policy" ON workout_progress;
DROP POLICY IF EXISTS "Users can update their own workout progress" ON workout_progress;
DROP POLICY IF EXISTS "Users can delete their own workout progress" ON workout_progress;
DROP POLICY IF EXISTS "Admins can view all workout progress" ON workout_progress;

-- SELECT: Usuarios ven su progreso, admins ven todo
CREATE POLICY "workout_progress_select_policy"
  ON workout_progress
  FOR SELECT
  USING (
    auth.uid() = user_id OR is_admin()
  );

-- INSERT: Usuarios solo su progreso
CREATE POLICY "workout_progress_insert_policy"
  ON workout_progress
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: Usuarios solo su progreso
CREATE POLICY "workout_progress_update_policy"
  ON workout_progress
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- DELETE: Usuarios solo su progreso
CREATE POLICY "workout_progress_delete_policy"
  ON workout_progress
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- TABLA: workout_ratings (valoraciones de workouts)
-- ============================================
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

-- Índices
CREATE INDEX IF NOT EXISTS idx_workout_ratings_user_id ON workout_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_ratings_workout_id ON workout_ratings(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_ratings_session_id ON workout_ratings(session_id);
CREATE INDEX IF NOT EXISTS idx_workout_ratings_created_at ON workout_ratings(created_at DESC);

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_workout_ratings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_workout_ratings_updated_at ON workout_ratings;
CREATE TRIGGER trigger_update_workout_ratings_updated_at
  BEFORE UPDATE ON workout_ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_ratings_updated_at();

-- RLS Policies
DROP POLICY IF EXISTS "workout_ratings_select_policy" ON workout_ratings;
DROP POLICY IF EXISTS "workout_ratings_insert_policy" ON workout_ratings;
DROP POLICY IF EXISTS "workout_ratings_update_policy" ON workout_ratings;
DROP POLICY IF EXISTS "workout_ratings_delete_policy" ON workout_ratings;
ALTER TABLE workout_ratings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own workout ratings" ON workout_ratings;
DROP POLICY IF EXISTS "Users can insert own workout ratings" ON workout_ratings;
DROP POLICY IF EXISTS "Users can update own workout ratings" ON workout_ratings;
DROP POLICY IF EXISTS "Users can delete own workout ratings" ON workout_ratings;
DROP POLICY IF EXISTS "Admins can view all workout ratings" ON workout_ratings;

-- SELECT: Usuarios ven sus ratings, admins ven todos
CREATE POLICY "workout_ratings_select_policy"
  ON workout_ratings
  FOR SELECT
  USING (
    auth.uid() = user_id OR is_admin()
  );

-- INSERT: Usuarios solo sus ratings
CREATE POLICY "workout_ratings_insert_policy"
  ON workout_ratings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: Usuarios solo sus ratings
CREATE POLICY "workout_ratings_update_policy"
  ON workout_ratings
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- DELETE: Usuarios solo sus ratings
CREATE POLICY "workout_ratings_delete_policy"
  ON workout_ratings
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- TABLA: user_goals (metas de usuarios)
-- ============================================
CREATE TABLE IF NOT EXISTS user_goals (
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

-- Índices
CREATE INDEX IF NOT EXISTS idx_user_goals_user_id ON user_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_user_goals_active ON user_goals(is_active);
CREATE INDEX IF NOT EXISTS idx_user_goals_dates ON user_goals(start_date, end_date);

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_user_goals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_user_goals_updated_at ON user_goals;
CREATE TRIGGER trigger_update_user_goals_updated_at
  BEFORE UPDATE ON user_goals
  FOR EACH ROW
  EXECUTE FUNCTION update_user_goals_updated_at();
DROP POLICY IF EXISTS "user_goals_select_policy" ON user_goals;
DROP POLICY IF EXISTS "user_goals_insert_policy" ON user_goals;
DROP POLICY IF EXISTS "user_goals_update_policy" ON user_goals;
DROP POLICY IF EXISTS "user_goals_delete_policy" ON user_goals;

-- RLS Policies
ALTER TABLE user_goals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own goals" ON user_goals;
DROP POLICY IF EXISTS "Users can create their own goals" ON user_goals;
DROP POLICY IF EXISTS "Users can update their own goals" ON user_goals;
DROP POLICY IF EXISTS "Users can delete their own goals" ON user_goals;

-- SELECT: Usuarios solo sus metas
CREATE POLICY "user_goals_select_policy"
  ON user_goals
  FOR SELECT
  USING (auth.uid() = user_id);

-- INSERT: Usuarios solo sus metas
CREATE POLICY "user_goals_insert_policy"
  ON user_goals
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: Usuarios solo sus metas
CREATE POLICY "user_goals_update_policy"
  ON user_goals
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- DELETE: Usuarios solo sus metas
CREATE POLICY "user_goals_delete_policy"
  ON user_goals
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- VERIFICACIÓN (opcional - solo para revisar)
-- ============================================

-- Ver todas las políticas actuales
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename IN ('users', 'workouts', 'exercises', 'meal_plans', 'workout_progress', 'workout_ratings', 'user_goals')
ORDER BY tablename, policyname;
