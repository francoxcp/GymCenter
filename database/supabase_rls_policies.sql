-- ============================================
-- SUPABASE ROW LEVEL SECURITY POLICIES
-- Chamos Fitness Center
-- ============================================

-- IMPORTANTE: Ejecutar estas políticas DESPUÉS de crear las tablas
-- Las políticas RLS protegen los datos a nivel de base de datos

-- ============================================
-- 1️⃣ HABILITAR RLS EN TODAS LAS TABLAS
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 2️⃣ POLÍTICAS PARA TABLA: users
-- ============================================

-- Los usuarios pueden ver SOLO su propio perfil
CREATE POLICY "users_select_own"
  ON users
  FOR SELECT
  USING (auth.uid() = id);

-- Los admins pueden ver TODOS los usuarios
CREATE POLICY "admins_select_all_users"
  ON users
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Los usuarios pueden actualizar SOLO su propio perfil
CREATE POLICY "users_update_own"
  ON users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Los admins pueden actualizar cualquier usuario (para asignar rutinas/dietas)
CREATE POLICY "admins_update_all_users"
  ON users
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo admins pueden insertar nuevos usuarios manualmente (registro lo hace auth.users)
CREATE POLICY "admins_insert_users"
  ON users
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================
-- 3️⃣ POLÍTICAS PARA TABLA: workouts
-- ============================================

-- TODOS pueden VER las rutinas (catálogo público)
CREATE POLICY "workouts_select_all"
  ON workouts
  FOR SELECT
  USING (true);

-- Solo ADMINS pueden crear rutinas
CREATE POLICY "admins_insert_workouts"
  ON workouts
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo ADMINS pueden actualizar rutinas
CREATE POLICY "admins_update_workouts"
  ON workouts
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo ADMINS pueden eliminar rutinas
CREATE POLICY "admins_delete_workouts"
  ON workouts
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================
-- 4️⃣ POLÍTICAS PARA TABLA: exercises
-- ============================================

-- TODOS pueden VER los ejercicios
CREATE POLICY "exercises_select_all"
  ON exercises
  FOR SELECT
  USING (true);

-- Solo ADMINS pueden crear ejercicios
CREATE POLICY "admins_insert_exercises"
  ON exercises
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo ADMINS pueden actualizar ejercicios
CREATE POLICY "admins_update_exercises"
  ON exercises
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo ADMINS pueden eliminar ejercicios
CREATE POLICY "admins_delete_exercises"
  ON exercises
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================
-- 5️⃣ POLÍTICAS PARA TABLA: meal_plans
-- ============================================

-- TODOS pueden VER los planes de comida (catálogo público)
CREATE POLICY "meal_plans_select_all"
  ON meal_plans
  FOR SELECT
  USING (true);

-- Solo ADMINS pueden crear planes
CREATE POLICY "admins_insert_meal_plans"
  ON meal_plans
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo ADMINS pueden actualizar planes
CREATE POLICY "admins_update_meal_plans"
  ON meal_plans
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo ADMINS pueden eliminar planes
CREATE POLICY "admins_delete_meal_plans"
  ON meal_plans
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================
-- 6️⃣ POLÍTICAS PARA TABLA: workout_sessions
-- ============================================

-- Los usuarios pueden ver SOLO sus propias sesiones
CREATE POLICY "workout_sessions_select_own"
  ON workout_sessions
  FOR SELECT
  USING (auth.uid() = user_id);

-- Los admins pueden ver TODAS las sesiones (para reportes)
CREATE POLICY "admins_select_all_sessions"
  ON workout_sessions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Los usuarios pueden crear SOLO sus propias sesiones
CREATE POLICY "workout_sessions_insert_own"
  ON workout_sessions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Los usuarios NO pueden actualizar sesiones (son inmutables)
-- Los admins tampoco (integridad histórica)

-- Los usuarios pueden eliminar SOLO sus propias sesiones
CREATE POLICY "workout_sessions_delete_own"
  ON workout_sessions
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- 7️⃣ POLÍTICAS PARA TABLA: body_measurements
-- ============================================

-- Los usuarios pueden ver SOLO sus propias medidas
CREATE POLICY "body_measurements_select_own"
  ON body_measurements
  FOR SELECT
  USING (auth.uid() = user_id);

-- Los usuarios pueden insertar SOLO sus propias medidas
CREATE POLICY "body_measurements_insert_own"
  ON body_measurements
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Los usuarios pueden actualizar SOLO sus propias medidas
CREATE POLICY "body_measurements_update_own"
  ON body_measurements
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Los usuarios pueden eliminar SOLO sus propias medidas
CREATE POLICY "body_measurements_delete_own"
  ON body_measurements
  FOR DELETE
  USING (auth.uid() = user_id);

-- Los admins pueden ver TODAS las medidas
CREATE POLICY "admins_select_all_body_measurements"
  ON body_measurements
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================
-- 8️⃣ POLÍTICAS PARA TABLA: user_preferences
-- ============================================

-- Los usuarios pueden ver SOLO sus propias preferencias
CREATE POLICY "user_preferences_select_own"
  ON user_preferences
  FOR SELECT
  USING (auth.uid() = user_id);

-- Los usuarios pueden actualizar SOLO sus propias preferencias
CREATE POLICY "user_preferences_update_own"
  ON user_preferences
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Los usuarios pueden insertar sus preferencias (autocreadas en trigger)
CREATE POLICY "user_preferences_insert_own"
  ON user_preferences
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 9️⃣ POLÍTICAS PARA TABLA: achievements
-- ============================================

-- TODOS pueden VER los logros disponibles (catálogo público)
CREATE POLICY "achievements_select_all"
  ON achievements
  FOR SELECT
  USING (true);

-- Solo ADMINS pueden crear logros
CREATE POLICY "admins_insert_achievements"
  ON achievements
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo ADMINS pueden actualizar logros
CREATE POLICY "admins_update_achievements"
  ON achievements
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================
-- 🔟 POLÍTICAS PARA TABLA: user_achievements
-- ============================================

-- Los usuarios pueden ver SOLO sus propios logros desbloqueados
CREATE POLICY "user_achievements_select_own"
  ON user_achievements
  FOR SELECT
  USING (auth.uid() = user_id);

-- Los usuarios pueden insertar sus propios logros (cuando los desbloquean)
CREATE POLICY "user_achievements_insert_own"
  ON user_achievements
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Los admins pueden ver TODOS los logros de usuarios
CREATE POLICY "admins_select_all_user_achievements"
  ON user_achievements
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================
-- 🔟 POLÍTICAS PARA TABLA: user_achievements
-- ============================================

-- Los usuarios pueden ver SOLO sus propios logros desbloqueados
CREATE POLICY "user_achievements_select_own"
  ON user_achievements
  FOR SELECT
  USING (auth.uid() = user_id);

-- Los usuarios pueden insertar sus propios logros (cuando los desbloquean)
CREATE POLICY "user_achievements_insert_own"
  ON user_achievements
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Los admins pueden ver TODOS los logros de usuarios
CREATE POLICY "admins_select_all_user_achievements"
  ON user_achievements
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================
-- FUNCIONES HELPER
-- ============================================

-- Función para verificar si el usuario actual es admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener el rol del usuario actual
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT role FROM users
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- NOTAS DE SEGURIDAD Y VERIFICACIÓN
-- ============================================

/*
✅ PRINCIPIOS APLICADOS:

1. **Principio de Mínimo Privilegio:**
   - Los usuarios solo acceden a SUS datos
   - Los admins tienen permisos completos

2. **Inmutabilidad del Historial:**
   - Las sesiones completadas NO se pueden editar
   - Mantiene integridad de reportes

3. **Catálogo Público:**
   - Workouts, MealPlans y Achievements visibles para todos
   - Fomenta exploración de rutinas disponibles

4. **Defensa en Profundidad:**
   - RLS + Auth + Validación en Flutter
   - Si alguien hackea el frontend, RLS lo detiene

📝 INSTRUCCIONES DE USO:

1. Ejecutar primero: supabase_schema.sql
2. Luego ejecutar: supabase_rls_policies.sql (este archivo)
3. Después ejecutar: storage_policies.sql
4. Finalmente: delete_account_function.sql

🧪 TESTING DE POLÍTICAS:

Verificar que RLS está habilitado en todas las tablas:
*/

-- Consulta para verificar políticas
SELECT schemaname, tablename, policyname, roles
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
