-- ============================================
-- FUNCIÓN PARA ELIMINAR CUENTA DE USUARIO
-- Chamos Fitness Center
-- ============================================
-- Ejecutar DESPUÉS de todas las otras configuraciones

CREATE OR REPLACE FUNCTION delete_user_account(user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Eliminar datos en orden correcto (respetando foreign keys)
    DELETE FROM user_achievements WHERE user_achievements.user_id = delete_user_account.user_id;
    DELETE FROM body_measurements WHERE body_measurements.user_id = delete_user_account.user_id;
    DELETE FROM workout_sessions WHERE workout_sessions.user_id = delete_user_account.user_id;
    DELETE FROM user_preferences WHERE user_preferences.user_id = delete_user_account.user_id;
    DELETE FROM users WHERE users.id = delete_user_account.user_id;
    
    -- Eliminar de auth.users (requiere privilegios de servicio)
    DELETE FROM auth.users WHERE id = delete_user_account.user_id;
    
    RAISE NOTICE 'Usuario % eliminado exitosamente', user_id;
END;
$$;

-- Dar permisos a usuarios autenticados
GRANT EXECUTE ON FUNCTION delete_user_account(UUID) TO authenticated;

-- ============================================
-- USO DESDE LA APP
-- ============================================

/*
Para llamar esta función desde Flutter:

await Supabase.instance.client.rpc(
  'delete_user_account',
  params: {'user_id': userId},
);

Esta función eliminará:
1. Logros del usuario
2. Medidas corporales
3. Historial de entrenamientos
4. Preferencias
5. Registro en tabla users
6. Cuenta de autenticación

⚠️ ADVERTENCIA: Esta acción es IRREVERSIBLE
*/
