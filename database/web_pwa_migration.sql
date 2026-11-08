-- ============================================================================
-- MIGRACIÓN: versión web (PWA) + Web Push + parche de seguridad
-- Ejecutar UNA vez en Supabase → SQL Editor (es idempotente: se puede
-- volver a ejecutar sin romper nada).
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
-- 4. Programar el envío cada 15 minutos (pg_cron + pg_net)
--    Requiere haber guardado en Vault (Project Settings → Vault):
--      - project_url       → https://<tu-proyecto>.supabase.co
--      - push_cron_secret  → el mismo valor que el secret CRON_SECRET de la
--                            Edge Function send-push
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

DO $$
BEGIN
  PERFORM cron.unschedule('chamos-send-push');
EXCEPTION WHEN OTHERS THEN
  NULL; -- no existía
END;
$$;

SELECT cron.schedule(
  'chamos-send-push',
  '*/15 * * * *',
  $$
  SELECT net.http_post(
    url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'project_url')
           || '/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'push_cron_secret')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  );
  $$
);
