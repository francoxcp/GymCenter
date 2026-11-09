-- =====================================================================
-- Feed de actividad con comentarios + Membresías y vencimientos
-- + bandeja de notificaciones push (push_outbox)
--
-- Requiere: roles_migration.sql, qa_fixes_migration.sql y
-- web_pwa_migration.sql ya aplicados. Es idempotente.
-- =====================================================================
BEGIN;

-- ---------------------------------------------------------------------
-- 1. Comentarios en cada entrenamiento terminado
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.session_comments (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.workout_sessions(id) ON DELETE CASCADE,
  author_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  body       TEXT NOT NULL CHECK (char_length(btrim(body)) BETWEEN 1 AND 500),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_session_comments_session
  ON public.session_comments (session_id, created_at);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_completed
  ON public.workout_sessions (completed_at DESC);

ALTER TABLE public.session_comments ENABLE ROW LEVEL SECURITY;

-- ¿Puede el usuario actual ver/comentar esta sesión? (dueño de la sesión,
-- su entrenador o el dueño del gimnasio)
CREATE OR REPLACE FUNCTION public.can_access_session(p_session UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT auth.uid() IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.workout_sessions s
     WHERE s.id = p_session
       AND (s.user_id = auth.uid() OR public.can_manage_user(s.user_id))
  );
$$;
REVOKE ALL ON FUNCTION public.can_access_session(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_access_session(UUID) TO authenticated;

DROP POLICY IF EXISTS sc_select ON public.session_comments;
DROP POLICY IF EXISTS sc_insert ON public.session_comments;
DROP POLICY IF EXISTS sc_delete ON public.session_comments;
CREATE POLICY sc_select ON public.session_comments FOR SELECT
  USING (public.can_access_session(session_id));
CREATE POLICY sc_insert ON public.session_comments FOR INSERT
  WITH CHECK (author_id = auth.uid() AND public.can_access_session(session_id));
CREATE POLICY sc_delete ON public.session_comments FOR DELETE
  USING (author_id = auth.uid() OR public.is_admin());

-- ---------------------------------------------------------------------
-- 2. Bandeja de notificaciones push (la procesa la función send-push)
--    Sin políticas: solo accesible con la service role / triggers.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.push_outbox (
  id         BIGSERIAL PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  url        TEXT NOT NULL DEFAULT '/home',
  tag        TEXT NOT NULL DEFAULT 'general',
  dedupe_key TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  sent_at    TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_push_outbox_pending
  ON public.push_outbox (created_at) WHERE sent_at IS NULL;
ALTER TABLE public.push_outbox ENABLE ROW LEVEL SECURITY;

-- Comentario nuevo → avisar a la otra parte
CREATE OR REPLACE FUNCTION public.notify_session_comment()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_owner   UUID;
  v_trainer UUID;
  v_author  TEXT;
  v_workout TEXT;
BEGIN
  SELECT s.user_id, u.trainer_id, w.name
    INTO v_owner, v_trainer, v_workout
    FROM public.workout_sessions s
    JOIN public.users u ON u.id = s.user_id
    LEFT JOIN public.workouts w ON w.id = s.workout_id
   WHERE s.id = NEW.session_id;
  SELECT name INTO v_author FROM public.users WHERE id = NEW.author_id;

  IF NEW.author_id <> v_owner THEN
    INSERT INTO public.push_outbox (user_id, title, body, url, tag)
    VALUES (v_owner,
            '💬 ' || COALESCE(v_author, 'Tu entrenador') || ' comentó tu entreno',
            left(NEW.body, 140),
            '/workout-history', 'comment');
  ELSIF v_trainer IS NOT NULL THEN
    INSERT INTO public.push_outbox (user_id, title, body, url, tag)
    VALUES (v_trainer,
            '💬 ' || COALESCE(v_author, 'Un socio') || ' · ' || COALESCE(v_workout, 'entreno'),
            left(NEW.body, 140),
            '/admin/activity', 'comment');
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS session_comments_notify ON public.session_comments;
CREATE TRIGGER session_comments_notify
  AFTER INSERT ON public.session_comments
  FOR EACH ROW EXECUTE FUNCTION public.notify_session_comment();

-- Entreno terminado → avisar al entrenador
CREATE OR REPLACE FUNCTION public.notify_session_done()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_trainer UUID;
  v_member  TEXT;
  v_workout TEXT;
BEGIN
  SELECT u.trainer_id, u.name INTO v_trainer, v_member
    FROM public.users u WHERE u.id = NEW.user_id;
  IF v_trainer IS NULL THEN RETURN NEW; END IF;
  SELECT name INTO v_workout FROM public.workouts WHERE id = NEW.workout_id;
  INSERT INTO public.push_outbox (user_id, title, body, url, tag)
  VALUES (v_trainer,
          '✅ ' || COALESCE(v_member, 'Un socio') || ' terminó su entreno',
          COALESCE(v_workout, 'Rutina') || ' · ' || COALESCE(NEW.duration_minutes, 0) || ' min',
          '/admin/activity', 'session_done');
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS workout_sessions_notify ON public.workout_sessions;
CREATE TRIGGER workout_sessions_notify
  AFTER INSERT ON public.workout_sessions
  FOR EACH ROW EXECUTE FUNCTION public.notify_session_done();

-- ---------------------------------------------------------------------
-- 3. Membresías
-- ---------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS membership_plan  TEXT,
  ADD COLUMN IF NOT EXISTS membership_start DATE,
  ADD COLUMN IF NOT EXISTS membership_end   DATE;
CREATE INDEX IF NOT EXISTS idx_users_membership_end
  ON public.users (membership_end) WHERE membership_end IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.membership_payments (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  plan         TEXT NOT NULL,
  amount       NUMERIC(10,2) CHECK (amount IS NULL OR amount >= 0),
  period_start DATE NOT NULL,
  period_end   DATE NOT NULL,
  created_by   UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_membership_payments_user
  ON public.membership_payments (user_id, created_at DESC);
ALTER TABLE public.membership_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mp_select ON public.membership_payments;
DROP POLICY IF EXISTS mp_delete ON public.membership_payments;
CREATE POLICY mp_select ON public.membership_payments FOR SELECT
  USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY mp_delete ON public.membership_payments FOR DELETE
  USING (public.is_admin());
-- Las altas se hacen solo con renew_membership()

-- El guardián de users: además, solo el dueño cambia la membresía
CREATE OR REPLACE FUNCTION public.users_guard()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
    IF TG_OP = 'INSERT' THEN
      NEW.role := 'user';
      NEW.trainer_id := NULL;
      NEW.trainer_code := NULL;
      NEW.assigned_workout_id := NULL;
      NEW.membership_plan := NULL;
      NEW.membership_start := NULL;
      NEW.membership_end := NULL;
    ELSE
      NEW.role := OLD.role;
      IF COALESCE(current_setting('app.trainer_link', true), '') <> '1' THEN
        NEW.trainer_id := OLD.trainer_id;
        NEW.trainer_code := OLD.trainer_code;
      END IF;
      IF OLD.id = auth.uid() THEN
        NEW.assigned_workout_id := OLD.assigned_workout_id;
      END IF;
      NEW.membership_plan := OLD.membership_plan;
      NEW.membership_start := OLD.membership_start;
      NEW.membership_end := OLD.membership_end;
    END IF;
  END IF;

  IF NEW.role IN ('trainer', 'admin') AND NEW.trainer_code IS NULL THEN
    NEW.trainer_code := public.gen_trainer_code();
  ELSIF NEW.role = 'user' THEN
    NEW.trainer_code := NULL;
  END IF;
  IF NEW.trainer_id = NEW.id THEN
    NEW.trainer_id := NULL;
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.users_guard() FROM PUBLIC, anon, authenticated;

-- Registrar un pago / renovación (solo el dueño). Extiende desde el
-- vencimiento actual si sigue vigente, o desde hoy si ya venció.
CREATE OR REPLACE FUNCTION public.renew_membership(
  p_user   UUID,
  p_plan   TEXT,
  p_months INT,
  p_amount NUMERIC DEFAULT NULL
) RETURNS DATE LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_today DATE := (now() AT TIME ZONE 'America/Costa_Rica')::date;
  v_end   DATE;
  v_start DATE;
  v_new   DATE;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo el dueño puede registrar membresías' USING ERRCODE = '42501';
  END IF;
  IF p_months IS NULL OR p_months < 1 OR p_months > 24 THEN
    RAISE EXCEPTION 'Meses inválidos';
  END IF;
  IF p_plan IS NULL OR char_length(btrim(p_plan)) = 0 OR char_length(p_plan) > 40 THEN
    RAISE EXCEPTION 'Plan inválido';
  END IF;

  SELECT membership_end INTO v_end FROM public.users WHERE id = p_user FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Socio no encontrado'; END IF;

  v_start := CASE WHEN v_end IS NOT NULL AND v_end >= v_today THEN v_end + 1 ELSE v_today END;
  v_new := (v_start + make_interval(months => p_months))::date - 1;

  UPDATE public.users
     SET membership_plan = btrim(p_plan),
         membership_start = CASE WHEN v_end IS NOT NULL AND v_end >= v_today
                                 THEN COALESCE(membership_start, v_start) ELSE v_start END,
         membership_end = v_new
   WHERE id = p_user;

  INSERT INTO public.membership_payments
    (user_id, plan, amount, period_start, period_end, created_by)
  VALUES (p_user, btrim(p_plan), p_amount, v_start, v_new, auth.uid());

  RETURN v_new;
END;
$$;
REVOKE ALL ON FUNCTION public.renew_membership(UUID, TEXT, INT, NUMERIC) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.renew_membership(UUID, TEXT, INT, NUMERIC) TO authenticated;

-- Avisos de vencimiento (3 días antes y el día que vence) → push_outbox
CREATE OR REPLACE FUNCTION public.enqueue_membership_reminders()
RETURNS INT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_today DATE := (now() AT TIME ZONE 'America/Costa_Rica')::date;
  n INT := 0;
BEGIN
  INSERT INTO public.push_outbox (user_id, title, body, url, tag, dedupe_key)
  SELECT u.id,
         CASE WHEN u.membership_end = v_today
              THEN '⏰ Tu membresía vence hoy'
              ELSE '⏰ Tu membresía vence en 3 días' END,
         'Renueva en recepción para seguir entrenando sin interrupciones.',
         '/profile', 'membership',
         'mem:' || u.id || ':' || u.membership_end || ':' || (u.membership_end - v_today)
    FROM public.users u
   WHERE u.membership_end IN (v_today, v_today + 3)
  ON CONFLICT (dedupe_key) DO NOTHING;
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END;
$$;
REVOKE ALL ON FUNCTION public.enqueue_membership_reminders() FROM PUBLIC, anon, authenticated;

-- Limpieza: avisos enviados de más de 30 días
CREATE OR REPLACE FUNCTION public.cleanup_push_outbox()
RETURNS VOID LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  DELETE FROM public.push_outbox WHERE created_at < now() - interval '30 days';
$$;
REVOKE ALL ON FUNCTION public.cleanup_push_outbox() FROM PUBLIC, anon, authenticated;

COMMIT;

-- Tareas programadas (fuera de la transacción: pg_cron)
DO $$
BEGIN
  PERFORM cron.unschedule('membership-reminders')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'membership-reminders');
  PERFORM cron.schedule('membership-reminders', '0 14 * * *',
    'SELECT public.enqueue_membership_reminders();');   -- 8:00 Costa Rica
  PERFORM cron.unschedule('push-outbox-cleanup')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'push-outbox-cleanup');
  PERFORM cron.schedule('push-outbox-cleanup', '30 9 * * 0',
    'SELECT public.cleanup_push_outbox();');
  -- Comentarios y avisos llegan en ≤ 5 min (antes cada 15)
  PERFORM cron.unschedule('gymlab-send-push')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'gymlab-send-push');
  PERFORM cron.schedule('gymlab-send-push', '*/5 * * * *',
    'SELECT public.trigger_send_push();');
END;
$$;
