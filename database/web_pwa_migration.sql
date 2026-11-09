-- ============================================================================
-- MIGRACIÓN: versión web (PWA) + Web Push + parche de seguridad
-- Ejecutar en Supabase → SQL Editor (es idempotente: se puede volver a
-- ejecutar sin romper nada). No requiere copiar ninguna clave secreta.
-- Ver docs/WEB_DEPLOY.md para el paso a paso completo.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. SEGURIDAD: el rol de un usuario nuevo SIEMPRE es 'user'.
--    Antes se copiaba raw_user_meta_data->>'role', lo que permitía a
--    cualquiera registrarse como 'admin' llamando a la API de Supabase.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role, level)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NULLIF(trim(NEW.raw_user_meta_data->>'name'), ''), 'Usuario Nuevo'),
    'user',
    'Principiante'
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. Preferencias necesarias para enviar recordatorios desde el servidor
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_preferences
  ADD COLUMN IF NOT EXISTS progress_reports BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS reminder_time TIME DEFAULT '18:00:00',
  ADD COLUMN IF NOT EXISTS timezone TEXT DEFAULT 'America/Costa_Rica',
  ADD COLUMN IF NOT EXISTS last_reminder_sent_on DATE,
  ADD COLUMN IF NOT EXISTS last_report_sent_on DATE;

-- ----------------------------------------------------------------------------
-- 3. Suscripciones Web Push (una por navegador/dispositivo)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.push_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  endpoint TEXT NOT NULL UNIQUE,
  p256dh TEXT NOT NULL,
  auth TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_push_subscriptions_user
  ON public.push_subscriptions(user_id);

ALTER TABLE public.push_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "push_subscriptions_select_own" ON public.push_subscriptions;
CREATE POLICY "push_subscriptions_select_own" ON public.push_subscriptions
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "push_subscriptions_insert_own" ON public.push_subscriptions;
CREATE POLICY "push_subscriptions_insert_own" ON public.push_subscriptions
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "push_subscriptions_update_own" ON public.push_subscriptions;
CREATE POLICY "push_subscriptions_update_own" ON public.push_subscriptions
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "push_subscriptions_delete_own" ON public.push_subscriptions;
CREATE POLICY "push_subscriptions_delete_own" ON public.push_subscriptions
  FOR DELETE USING (user_id = auth.uid());

-- Si un mismo navegador se usa con otra cuenta, el upsert por endpoint
-- debe poder "mudar" la fila al usuario actual. Esta función lo permite
-- sin abrir el UPDATE sobre filas ajenas.
CREATE OR REPLACE FUNCTION public.claim_push_subscription(
  p_endpoint TEXT, p_p256dh TEXT, p_auth TEXT
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;
  INSERT INTO public.push_subscriptions (user_id, endpoint, p256dh, auth)
  VALUES (auth.uid(), p_endpoint, p_p256dh, p_auth)
  ON CONFLICT (endpoint) DO UPDATE
    SET user_id = auth.uid(),
        p256dh = EXCLUDED.p256dh,
        auth = EXCLUDED.auth,
        updated_at = NOW();
END;
$$;

REVOKE ALL ON FUNCTION public.claim_push_subscription(TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_push_subscription(TEXT, TEXT, TEXT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 4. Configuración interna de Web Push (sin secretos que copiar a mano)
--    - cron_secret: se genera aquí automáticamente.
--    - vapid_public / vapid_private: las genera la Edge Function send-push
--      la primera vez que se ejecuta.
--    - project_url: URL pública del proyecto (no es secreta).
--    La tabla tiene RLS sin políticas: solo la base de datos y la Edge
--    Function (service role) pueden leerla.
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE TABLE IF NOT EXISTS public.push_config (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  project_url TEXT,
  cron_secret TEXT NOT NULL DEFAULT encode(extensions.gen_random_bytes(32), 'hex'),
  vapid_public TEXT,
  vapid_private TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.push_config ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.push_config FROM anon, authenticated;

INSERT INTO public.push_config (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

-- La app obtiene la clave pública VAPID (no es secreta) con esta función.
CREATE OR REPLACE FUNCTION public.get_vapid_public_key()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT vapid_public FROM public.push_config WHERE id = 1;
$$;
REVOKE ALL ON FUNCTION public.get_vapid_public_key() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_vapid_public_key() TO authenticated;

-- ----------------------------------------------------------------------------
-- 5. Programar el envío cada 15 minutos (pg_cron + pg_net)
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Función que llama a la Edge Function (también sirve para probar a mano:
--   SELECT public.trigger_send_push();
CREATE OR REPLACE FUNCTION public.trigger_send_push()
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  cfg public.push_config;
  req_id BIGINT;
BEGIN
  SELECT * INTO cfg FROM public.push_config WHERE id = 1;
  IF cfg.project_url IS NULL OR cfg.project_url = '' THEN
    RAISE NOTICE 'push_config.project_url no está configurado';
    RETURN NULL;
  END IF;
  SELECT net.http_post(
    url := rtrim(cfg.project_url, '/') || '/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || cfg.cron_secret
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  ) INTO req_id;
  RETURN req_id;
END;
$$;
REVOKE ALL ON FUNCTION public.trigger_send_push() FROM PUBLIC, anon, authenticated;

DO $$
BEGIN
  PERFORM cron.unschedule('gymlab-send-push');
EXCEPTION WHEN OTHERS THEN
  NULL; -- no existía
END;
$$;

SELECT cron.schedule('gymlab-send-push', '*/15 * * * *', $$SELECT public.trigger_send_push();$$);

-- ----------------------------------------------------------------------------
-- 6. ÚLTIMO PASO: indica la URL de tu proyecto (no es secreta).
--    Reemplaza el valor y ejecuta esta línea:
-- UPDATE public.push_config SET project_url = 'https://xxxx.supabase.co' WHERE id = 1;
-- ----------------------------------------------------------------------------
