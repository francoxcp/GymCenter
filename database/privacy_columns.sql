-- ============================================================================
-- Migración: Agregar columnas de privacidad a user_preferences
-- ============================================================================
-- Ejecutar en el SQL Editor de Supabase Dashboard
-- Estas columnas permiten persistir las preferencias de privacidad del usuario
-- en el servidor en lugar de solo en SharedPreferences local.
-- ============================================================================

-- Agregar columnas de privacidad
ALTER TABLE user_preferences
  ADD COLUMN IF NOT EXISTS privacy_analytics BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS privacy_personalization BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS privacy_workout_insights BOOLEAN DEFAULT TRUE;

-- Verificar que las columnas se crearon correctamente
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'user_preferences'
  AND column_name LIKE 'privacy_%';
