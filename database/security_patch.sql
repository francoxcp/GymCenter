-- ============================================
-- PARCHE DE SEGURIDAD: RLS + ROLE PROTECTION
-- Chamos Fitness Center
-- ============================================
-- Ejecutar en Supabase SQL Editor INMEDIATAMENTE.
-- Corrige: tablas sin RLS, escalación de rol a admin,
--          fotos de perfil accesibles públicamente,
--          datos huérfanos al eliminar cuenta.
-- ============================================

-- ============================================
-- 1. HABILITAR RLS EN TABLAS DESPROTEGIDAS
-- ============================================

ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 2. POLÍTICAS: workout_sessions
-- ============================================

DROP POLICY IF EXISTS "ws_select" ON workout_sessions;
DROP POLICY IF EXISTS "ws_insert" ON workout_sessions;
DROP POLICY IF EXISTS "ws_update" ON workout_sessions;
DROP POLICY IF EXISTS "ws_delete" ON workout_sessions;

CREATE POLICY "ws_select" ON workout_sessions FOR SELECT
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "ws_insert" ON workout_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "ws_update" ON workout_sessions FOR UPDATE
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "ws_delete" ON workout_sessions FOR DELETE
  USING (auth.uid() = user_id OR is_admin());

-- ============================================
-- 3. POLÍTICAS: body_measurements
-- ============================================

DROP POLICY IF EXISTS "bm_select" ON body_measurements;
DROP POLICY IF EXISTS "bm_insert" ON body_measurements;
DROP POLICY IF EXISTS "bm_update" ON body_measurements;
DROP POLICY IF EXISTS "bm_delete" ON body_measurements;

CREATE POLICY "bm_select" ON body_measurements FOR SELECT
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "bm_insert" ON body_measurements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "bm_update" ON body_measurements FOR UPDATE
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "bm_delete" ON body_measurements FOR DELETE
  USING (auth.uid() = user_id OR is_admin());

-- ============================================
-- 4. POLÍTICAS: user_preferences
-- ============================================

DROP POLICY IF EXISTS "up_select" ON user_preferences;
DROP POLICY IF EXISTS "up_insert" ON user_preferences;
DROP POLICY IF EXISTS "up_update" ON user_preferences;
DROP POLICY IF EXISTS "up_delete" ON user_preferences;

CREATE POLICY "up_select" ON user_preferences FOR SELECT
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "up_insert" ON user_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "up_update" ON user_preferences FOR UPDATE
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "up_delete" ON user_preferences FOR DELETE
  USING (auth.uid() = user_id OR is_admin());

-- ============================================
-- 5. POLÍTICAS: user_achievements
-- ============================================

DROP POLICY IF EXISTS "ua_select" ON user_achievements;
DROP POLICY IF EXISTS "ua_insert" ON user_achievements;
DROP POLICY IF EXISTS "ua_delete" ON user_achievements;

CREATE POLICY "ua_select" ON user_achievements FOR SELECT
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "ua_insert" ON user_achievements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "ua_delete" ON user_achievements FOR DELETE
  USING (auth.uid() = user_id OR is_admin());

-- ============================================
-- 6. PROTEGER CAMPO 'role' CONTRA ESCALACIÓN
-- ============================================
-- Un usuario normal NO puede cambiar su propio campo 'role'.
-- Reemplaza la política de UPDATE en users.

DROP POLICY IF EXISTS "users_update_policy" ON users;

CREATE POLICY "users_update_policy"
  ON users
  FOR UPDATE
  USING (is_admin() OR id = auth.uid())
  WITH CHECK (
    CASE
      -- Admins pueden actualizar cualquier campo
      WHEN is_admin() THEN true
      -- Usuarios normales: solo si no cambian el campo 'role'
      WHEN id = auth.uid() THEN role = (SELECT role FROM users WHERE id = auth.uid())
      ELSE false
    END
  );

-- ============================================
-- 7. FOTOS DE PERFIL: SOLO AUTENTICADOS
-- ============================================
-- Cambiar de público (TO public) a solo usuarios autenticados.

DROP POLICY IF EXISTS "Profile photos are publicly accessible" ON storage.objects;

CREATE POLICY "Profile photos visible to authenticated users"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'profile-photos');

-- ============================================
-- 8. FUNCIÓN delete_user_account MEJORADA
-- ============================================
-- Ahora elimina TODAS las tablas + archivos de storage.

DROP FUNCTION IF EXISTS delete_user_account(UUID);

CREATE OR REPLACE FUNCTION delete_user_account(target_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verificar que el usuario autenticado es el mismo o es admin
  IF auth.uid() != target_user_id AND NOT is_admin() THEN
    RAISE EXCEPTION 'No autorizado para eliminar esta cuenta';
  END IF;

  -- Eliminar datos de TODAS las tablas con user_id (orden por FK)
  DELETE FROM user_achievements WHERE user_id = target_user_id;
  DELETE FROM user_workout_schedule WHERE user_id = target_user_id;
  DELETE FROM workout_progress WHERE user_id = target_user_id;
  DELETE FROM workout_ratings WHERE user_id = target_user_id;
  DELETE FROM body_measurements WHERE user_id = target_user_id;
  DELETE FROM workout_sessions WHERE user_id = target_user_id;
  DELETE FROM user_preferences WHERE user_id = target_user_id;
  DELETE FROM users WHERE id = target_user_id;

  -- Eliminar archivos de storage (fotos de perfil)
  DELETE FROM storage.objects
    WHERE bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = target_user_id::text;

  -- Eliminar cuenta de auth
  DELETE FROM auth.users WHERE id = target_user_id;

  RAISE NOTICE 'Usuario % eliminado completamente', target_user_id;
END;
$$;

-- Re-conceder permisos
GRANT EXECUTE ON FUNCTION delete_user_account(UUID) TO authenticated;
