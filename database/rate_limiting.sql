-- ============================================
-- RATE LIMITING & ACCOUNT LOCKOUT (SERVER-SIDE)
-- Chamos Fitness Center
-- ============================================
-- Ejecutar en Supabase SQL Editor.
-- Agrega protección contra brute force a nivel de servidor.
-- ============================================

-- 1. Tabla de intentos de login
CREATE TABLE IF NOT EXISTS login_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  ip_address TEXT,
  success BOOLEAN NOT NULL DEFAULT false,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índice para consultas de rate limiting
CREATE INDEX IF NOT EXISTS idx_login_attempts_email_time
  ON login_attempts (email, attempted_at DESC);

-- Auto-limpiar registros > 24h (para no llenar la tabla)
CREATE INDEX IF NOT EXISTS idx_login_attempts_cleanup
  ON login_attempts (attempted_at);

-- 2. RLS: solo el sistema puede escribir (via SECURITY DEFINER functions)
ALTER TABLE login_attempts ENABLE ROW LEVEL SECURITY;

-- No dar acceso directo a la tabla
DROP POLICY IF EXISTS "login_attempts_deny_all" ON login_attempts;
CREATE POLICY "login_attempts_deny_all" ON login_attempts
  FOR ALL USING (false);

-- 3. Función para registrar un intento y verificar rate limit
--    Retorna TRUE si el login está permitido, FALSE si bloqueado.
CREATE OR REPLACE FUNCTION check_login_rate_limit(target_email TEXT)
RETURNS TABLE(allowed BOOLEAN, wait_seconds INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  recent_failed INT;
  last_attempt TIMESTAMPTZ;
  lockout_until TIMESTAMPTZ;
BEGIN
  -- Contar intentos fallidos en los últimos 15 minutos
  SELECT COUNT(*), MAX(attempted_at)
  INTO recent_failed, last_attempt
  FROM login_attempts
  WHERE email = target_email
    AND success = false
    AND attempted_at > now() - INTERVAL '15 minutes';

  -- Si >= 10 intentos fallidos en 15 min, bloquear 1 hora desde el último intento
  IF recent_failed >= 10 THEN
    lockout_until := last_attempt + INTERVAL '1 hour';
    IF now() < lockout_until THEN
      RETURN QUERY SELECT false, EXTRACT(EPOCH FROM (lockout_until - now()))::INT;
      RETURN;
    END IF;
  -- Si >= 5 intentos fallidos, bloquear 5 minutos
  ELSIF recent_failed >= 5 THEN
    lockout_until := last_attempt + INTERVAL '5 minutes';
    IF now() < lockout_until THEN
      RETURN QUERY SELECT false, EXTRACT(EPOCH FROM (lockout_until - now()))::INT;
      RETURN;
    END IF;
  END IF;

  RETURN QUERY SELECT true, 0;
END;
$$;

-- 4. Función para registrar un intento (llamar desde el trigger o app)
CREATE OR REPLACE FUNCTION record_login_attempt(
  target_email TEXT,
  was_successful BOOLEAN,
  client_ip TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO login_attempts (email, ip_address, success)
  VALUES (target_email, client_ip, was_successful);

  -- Limpiar intentos > 24 horas para mantener la tabla ligera
  DELETE FROM login_attempts
  WHERE attempted_at < now() - INTERVAL '24 hours';
END;
$$;

-- 5. Función de limpieza periódica (opcional: ejecutar con pg_cron si disponible)
CREATE OR REPLACE FUNCTION cleanup_old_login_attempts()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM login_attempts
  WHERE attempted_at < now() - INTERVAL '7 days';
END;
$$;
