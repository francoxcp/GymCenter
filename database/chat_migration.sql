-- =====================================================================
-- Chat socio ↔ entrenador + invitación "Soy socio, no entrenador".
--
-- Cada socio tiene UNA conversación: con su entrenador actual
-- (users.trainer_id). Solo esos dos la leen y escriben; ni el dueño ni
-- otros entrenadores. Si cambia de entrenador, el anterior deja de verla.
--
-- Requiere multitenant_migration.sql, saas_v2_migration.sql y
-- ux_feed_membership_migration.sql (push_outbox). Idempotente.
-- =====================================================================
BEGIN;

-- ---------------------------------------------------------------------
-- 1. Aceptar una invitación de entrenador como socio (solo baja permisos)
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.accept_invitation(TEXT);
CREATE OR REPLACE FUNCTION public.accept_invitation(
  p_token TEXT, p_as_member BOOLEAN DEFAULT false
) RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_inv  RECORD;
  v_me   RECORD;
  v_org_name TEXT;
  v_role TEXT;      -- rol que otorga la invitación (o 'user' si lo pidió)
  v_new_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not_authenticated'; END IF;
  SELECT * INTO v_inv FROM public.invitations
   WHERE token = upper(trim(p_token)) FOR UPDATE;
  IF NOT FOUND OR v_inv.revoked OR v_inv.uses >= v_inv.max_uses OR v_inv.expires_at <= now() THEN
    RAISE EXCEPTION 'invalid_invitation';
  END IF;
  SELECT name INTO v_org_name FROM public.organizations
   WHERE id = v_inv.org_id AND status = 'active' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_invitation'; END IF;

  SELECT id, role, org_id INTO v_me FROM public.users WHERE id = auth.uid() FOR UPDATE;
  IF v_me.org_id IS NOT NULL AND v_me.org_id <> v_inv.org_id THEN
    RAISE EXCEPTION 'already_in_other_org';
  END IF;

  v_role := CASE WHEN COALESCE(p_as_member, false) THEN 'user' ELSE v_inv.role END;
  v_new_role := CASE
    WHEN v_role = 'admin' THEN 'admin'
    WHEN v_role = 'trainer' AND v_me.role = 'user' THEN 'trainer'
    ELSE v_me.role END;

  IF v_me.org_id = v_inv.org_id AND v_new_role = v_me.role THEN
    RETURN v_org_name;
  END IF;

  IF v_new_role = 'user' AND v_me.org_id IS NULL
     AND NOT COALESCE(public.org_has_room(v_inv.org_id), true) THEN
    RAISE EXCEPTION 'member_limit';
  END IF;

  PERFORM set_config('app.org_link', '1', true);
  PERFORM set_config('app.invite_role', '1', true);
  PERFORM set_config('app.trainer_link', '1', true);
  UPDATE public.users
     SET org_id = v_inv.org_id,
         role = v_new_role,
         trainer_id = CASE
           WHEN v_new_role <> 'user' THEN NULL
           WHEN v_inv.role = 'user' THEN COALESCE(trainer_id, v_inv.trainer_id)
           ELSE trainer_id END
   WHERE id = auth.uid();
  PERFORM set_config('app.org_link', '', true);
  PERFORM set_config('app.invite_role', '', true);
  PERFORM set_config('app.trainer_link', '', true);

  -- Un enlace de entrenador usado "como socio" no se gasta
  IF v_role = v_inv.role THEN
    UPDATE public.invitations SET uses = uses + 1 WHERE id = v_inv.id;
  END IF;
  RETURN v_org_name;
END;
$$;
REVOKE ALL ON FUNCTION public.accept_invitation(TEXT, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_invitation(TEXT, BOOLEAN) TO authenticated;

-- ---------------------------------------------------------------------
-- 2. Mensajes directos
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.direct_messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  trainer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  sender_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  body       TEXT NOT NULL CHECK (char_length(btrim(body)) BETWEEN 1 AND 2000),
  session_id UUID REFERENCES public.workout_sessions(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at    TIMESTAMPTZ,
  CHECK (sender_id IN (member_id, trainer_id))
);
CREATE INDEX IF NOT EXISTS idx_dm_thread
  ON public.direct_messages (member_id, trainer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_dm_trainer_unread
  ON public.direct_messages (trainer_id) WHERE read_at IS NULL;

-- ¿Es esta la conversación vigente (el entrenador actual del socio) y
-- participo yo en ella?
CREATE OR REPLACE FUNCTION public.can_chat(p_member UUID, p_trainer UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT auth.uid() IN (p_member, p_trainer)
     AND EXISTS (
       SELECT 1 FROM public.users m
         JOIN public.users t ON t.id = m.trainer_id
        WHERE m.id = p_member AND m.trainer_id = p_trainer
          AND m.org_id IS NOT NULL AND m.org_id = t.org_id);
$$;
REVOKE ALL ON FUNCTION public.can_chat(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_chat(UUID, UUID) TO authenticated;

ALTER TABLE public.direct_messages ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.direct_messages FROM anon;
REVOKE UPDATE, DELETE ON public.direct_messages FROM authenticated;
DROP POLICY IF EXISTS dm_select ON public.direct_messages;
DROP POLICY IF EXISTS dm_insert ON public.direct_messages;
CREATE POLICY dm_select ON public.direct_messages FOR SELECT TO authenticated
  USING (public.can_chat(member_id, trainer_id));
CREATE POLICY dm_insert ON public.direct_messages FOR INSERT TO authenticated
  WITH CHECK (sender_id = auth.uid() AND read_at IS NULL
              AND public.can_chat(member_id, trainer_id));

-- Tiempo real (respeta RLS)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (SELECT 1 FROM pg_publication_tables
                      WHERE pubname = 'supabase_realtime'
                        AND schemaname = 'public' AND tablename = 'direct_messages') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_messages;
  END IF;
END $$;

-- ---------------------------------------------------------------------
-- 3. Funciones del chat
-- ---------------------------------------------------------------------
-- Chats del entrenador: todos sus socios, con último mensaje y no leídos
CREATE OR REPLACE FUNCTION public.my_chats()
RETURNS TABLE(member_id UUID, name TEXT, photo_url TEXT, last_body TEXT,
              last_at TIMESTAMPTZ, last_from_me BOOLEAN, unread INT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT m.id, m.name, m.photo_url, l.body, l.created_at,
         l.sender_id = auth.uid(),
         (SELECT count(*)::int FROM public.direct_messages d
           WHERE d.member_id = m.id AND d.trainer_id = auth.uid()
             AND d.sender_id = m.id AND d.read_at IS NULL)
    FROM public.users m
    LEFT JOIN LATERAL (
      SELECT d.body, d.created_at, d.sender_id FROM public.direct_messages d
       WHERE d.member_id = m.id AND d.trainer_id = auth.uid()
       ORDER BY d.created_at DESC LIMIT 1) l ON true
   WHERE m.trainer_id = auth.uid() AND m.role = 'user'
     AND m.org_id = public.my_org_id()
   ORDER BY 7 DESC, l.created_at DESC NULLS LAST, m.name;
$$;
REVOKE ALL ON FUNCTION public.my_chats() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.my_chats() TO authenticated;

-- Mensajes sin leer para mí (socio: de su entrenador; entrenador: de todos)
CREATE OR REPLACE FUNCTION public.chat_unread_count()
RETURNS INT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT count(*)::int FROM public.direct_messages d
    JOIN public.users m ON m.id = d.member_id
   WHERE d.read_at IS NULL AND d.sender_id <> auth.uid()
     AND auth.uid() IN (d.member_id, d.trainer_id)
     AND m.trainer_id = d.trainer_id;
$$;
REVOKE ALL ON FUNCTION public.chat_unread_count() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.chat_unread_count() TO authenticated;

-- Marcar como leída la conversación con ese socio (lo que me escribieron)
CREATE OR REPLACE FUNCTION public.mark_chat_read(p_member UUID)
RETURNS VOID LANGUAGE sql VOLATILE SECURITY DEFINER SET search_path = public AS $$
  UPDATE public.direct_messages d SET read_at = now()
    FROM public.users m
   WHERE m.id = p_member AND d.member_id = p_member
     AND d.trainer_id = m.trainer_id
     AND auth.uid() IN (d.member_id, d.trainer_id)
     AND d.sender_id <> auth.uid() AND d.read_at IS NULL;
$$;
REVOKE ALL ON FUNCTION public.mark_chat_read(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_chat_read(UUID) TO authenticated;

-- ---------------------------------------------------------------------
-- 4. Aviso push por mensaje (uno por ráfaga: si ya había otro sin leer en
--    los últimos 10 min, no vuelve a sonar)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_direct_message()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_to   UUID := CASE WHEN NEW.sender_id = NEW.member_id THEN NEW.trainer_id ELSE NEW.member_id END;
  v_from TEXT;
BEGIN
  IF EXISTS (SELECT 1 FROM public.direct_messages d
              WHERE d.member_id = NEW.member_id AND d.trainer_id = NEW.trainer_id
                AND d.sender_id = NEW.sender_id AND d.id <> NEW.id
                AND d.read_at IS NULL
                AND d.created_at > now() - interval '10 minutes') THEN
    RETURN NEW;
  END IF;
  SELECT name INTO v_from FROM public.users WHERE id = NEW.sender_id;
  INSERT INTO public.push_outbox (user_id, title, body, url, tag)
  VALUES (v_to, 'Mensaje de ' || COALESCE(split_part(v_from, ' ', 1), 'tu entrenador'),
          left(NEW.body, 140),
          CASE WHEN v_to = NEW.member_id THEN '/chat' ELSE '/chats/' || NEW.member_id END,
          'chat');
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_notify_direct_message ON public.direct_messages;
CREATE TRIGGER trg_notify_direct_message
  AFTER INSERT ON public.direct_messages
  FOR EACH ROW EXECUTE FUNCTION public.notify_direct_message();

-- ---------------------------------------------------------------------
-- 5. Pasar al chat los comentarios de entrenos entre socio y su
--    entrenador actual (quedan como leídos; no generan avisos)
-- ---------------------------------------------------------------------
ALTER TABLE public.direct_messages DISABLE TRIGGER trg_notify_direct_message;
INSERT INTO public.direct_messages
  (member_id, trainer_id, sender_id, body, session_id, created_at, read_at)
SELECT s.user_id, m.trainer_id, c.author_id, c.body, c.session_id, c.created_at, c.created_at
  FROM public.session_comments c
  JOIN public.workout_sessions s ON s.id = c.session_id
  JOIN public.users m ON m.id = s.user_id
 WHERE m.trainer_id IS NOT NULL
   AND c.author_id IN (s.user_id, m.trainer_id)
   AND NOT EXISTS (SELECT 1 FROM public.direct_messages d
                    WHERE d.sender_id = c.author_id AND d.created_at = c.created_at
                      AND d.body = c.body);
ALTER TABLE public.direct_messages ENABLE TRIGGER trg_notify_direct_message;

COMMIT;
