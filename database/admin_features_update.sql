-- ============================================
-- ACTUALIZACIÓN DE SCHEMA - ALTA PRIORIDAD
-- Funcionalidades de Administrador
-- ============================================
-- EJECUTAR SOLO SI NO HAS EJECUTADO supabase_schema.sql COMPLETO

-- Agregar columna is_active para suspender/activar usuarios
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Índices adicionales para admin (idx_users_role ya existe en schema principal)
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Comentarios para documentación
COMMENT ON COLUMN users.is_active IS 'Indica si el usuario está activo o suspendido';
COMMENT ON COLUMN users.assigned_workout_id IS 'Rutina asignada al usuario por un administrador';
COMMENT ON COLUMN users.assigned_meal_plan_id IS 'Plan alimenticio asignado al usuario por un administrador';
