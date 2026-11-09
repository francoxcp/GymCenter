-- =====================================================================
-- UX por rol: bandeja de avisos dentro de la app, notas privadas del
-- entrenador, teléfono (WhatsApp), copiar plan entre socios, historia
-- del cliente para la plataforma y enlace directo al comprobante.
--
-- Requiere multitenant_migration.sql y saas_v2_migration.sql. Idempotente.
-- =====================================================================
BEGIN;

-- ---------------------------------------------------------------------
-- 1. Bandeja de avisos (reutiliza push_outbox: comentarios, entrenos,
--    pagos, vencimientos). La tabla sigue cerrada; se lee con funciones.
-- ---------------------------------------------------------------------
ALTER TABLE public.push_outbox ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_push_outbox_user
  ON public.push_outbox (user_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.my_notifications(p_limit INT DEFAULT 40)
RETURNS TABLE(id BIGINT, title TEXT, body TEXT, url TEXT, tag TEXT,
              created_at TIMESTAMPTZ, read BOOLEAN)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT o.id, o.title, o.body, o.url, o.tag, o.created_at, o.read_at IS NOT NULL
    FROM public.push_outbox o
   WHERE o.user_id = auth.uid()
     AND o.created_at > now() - interval '30 days'
   ORDER BY o.created_at DESC
   LIMIT LEAST(GREATEST(COALESCE(p_limit, 40), 1), 100);
$$;
REVOKE ALL ON FUNCTION public.my_notifications(INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.my_notifications(INT) TO authenticated;

CREATE OR REPLACE FUNCTION public.my_unread_notifications()
RETURNS INT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT count(*)::int FROM public.push_outbox
   WHERE user_id = auth.uid() AND read_at IS NULL
     AND created_at > now() - interval '30 days';
$$;
REVOKE ALL ON FUNCTION public.my_unread_notifications() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.my_unread_notifications() TO authenticated;

CREATE OR REPLACE FUNCTION public.mark_my_notifications_read()
RETURNS VOID LANGUAGE sql VOLATILE SECURITY DEFINER SET search_path = public AS $$
  UPDATE public.push_outbox SET read_at = now()
   WHERE user_id = auth.uid() AND read_at IS NULL;
$$;
REVOKE ALL ON FUNCTION public.mark_my_notifications_read() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_my_notifications_read() TO authenticated;

-- ---------------------------------------------------------------------
-- 2. Notas privadas por socio (las ve el dueño y su entrenador, nunca
--    el socio)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.member_notes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  -- Si se elimina al entrenador la nota se conserva para el gimnasio
  author_id  UUID REFERENCES public.users(id) ON DELETE SET NULL,
  body       TEXT NOT NULL CHECK (char_length(btrim(body)) BETWEEN 1 AND 1000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_member_notes_member
  ON public.member_notes (member_id, created_at DESC);
ALTER TABLE public.member_notes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.member_notes FROM anon;

DROP POLICY IF EXISTS mn_select ON public.member_notes;
DROP POLICY IF EXISTS mn_insert ON public.member_notes;
DROP POLICY IF EXISTS mn_delete ON public.member_notes;
CREATE POLICY mn_select ON public.member_notes FOR SELECT TO authenticated
  USING (public.can_manage_user(member_id));
CREATE POLICY mn_insert ON public.member_notes FOR INSERT TO authenticated
  WITH CHECK (author_id = auth.uid() AND public.can_manage_user(member_id));
CREATE POLICY mn_delete ON public.member_notes FOR DELETE TO authenticated
  USING (author_id = auth.uid() OR public.owns_member(member_id));

-- ---------------------------------------------------------------------
-- 3. Teléfono (para escribir por WhatsApp al entrenador)
-- ---------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS phone TEXT
    CHECK (phone IS NULL OR phone ~ '^\+?[0-9][0-9 ]{6,19}$');

-- ---------------------------------------------------------------------
-- 4. Copiar el plan semanal de un socio a otro
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.copy_member_plan(p_from UUID, p_to UUID)
RETURNS INT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE n INT;
BEGIN
  IF p_from = p_to OR NOT public.can_manage_user(p_from)
     OR NOT public.can_manage_user(p_to)
     OR NOT EXISTS (SELECT 1 FROM public.users WHERE id = p_to AND role = 'user') THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  DELETE FROM public.user_workout_schedule WHERE user_id = p_to;
  INSERT INTO public.user_workout_schedule (user_id, workout_id, day_of_week)
  SELECT p_to, workout_id, day_of_week
    FROM public.user_workout_schedule WHERE user_id = p_from;
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END;
$$;
REVOKE ALL ON FUNCTION public.copy_member_plan(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.copy_member_plan(UUID, UUID) TO authenticated;

-- ---------------------------------------------------------------------
-- 5. Plataforma: última actividad del cliente (¿de verdad lo usa?)
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.platform_list_orgs();
CREATE FUNCTION public.platform_list_orgs()
RETURNS TABLE(id UUID, name TEXT, kind TEXT, logo_url TEXT, status TEXT,
              billing_status TEXT, billing_note TEXT, paid_until DATE,
              monthly_fee NUMERIC, plan TEXT, max_members INT, in_trial BOOLEAN,
              owner_name TEXT, owner_email TEXT,
              trainers BIGINT, members BIGINT, pending_reviews BIGINT,
              created_at TIMESTAMPTZ, last_activity TIMESTAMPTZ,
              sessions_30d BIGINT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT o.id, o.name, o.kind, o.logo_url, o.status, o.billing_status, o.billing_note,
         o.paid_until, o.monthly_fee, o.plan, o.max_members,
         NOT EXISTS (SELECT 1 FROM public.org_payments p
                      WHERE p.org_id = o.id AND p.status = 'approved')
           AND o.plan <> 'Interno',
         (SELECT u.name FROM public.users u WHERE u.org_id = o.id AND u.role = 'admin'
           ORDER BY u.created_at LIMIT 1),
         (SELECT u.email FROM public.users u WHERE u.org_id = o.id AND u.role = 'admin'
           ORDER BY u.created_at LIMIT 1),
         (SELECT count(*) FROM public.users u WHERE u.org_id = o.id AND u.role = 'trainer'),
         (SELECT count(*) FROM public.users u WHERE u.org_id = o.id AND u.role = 'user'),
         (SELECT count(*) FROM public.org_payments p WHERE p.org_id = o.id AND p.status = 'in_review'),
         o.created_at,
         (SELECT max(s.completed_at) FROM public.workout_sessions s
            JOIN public.users u ON u.id = s.user_id WHERE u.org_id = o.id),
         (SELECT count(*) FROM public.workout_sessions s
            JOIN public.users u ON u.id = s.user_id
           WHERE u.org_id = o.id AND s.completed_at > now() - interval '30 days')
    FROM public.organizations o
   WHERE public.is_platform_admin()
   ORDER BY (SELECT count(*) FROM public.org_payments p
              WHERE p.org_id = o.id AND p.status = 'in_review') DESC, o.name;
$$;
REVOKE ALL ON FUNCTION public.platform_list_orgs() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_list_orgs() TO authenticated;

-- ---------------------------------------------------------------------
-- 6. El aviso de comprobante abre directo ese cliente
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_org_payment(
  p_months INT, p_amount NUMERIC, p_receipt_path TEXT
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_org  UUID := public.my_org_id();
  v_name TEXT;
  v_id   UUID;
BEGIN
  IF NOT public.is_admin() OR v_org IS NULL THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  IF p_receipt_path IS NULL OR split_part(p_receipt_path, '/', 1) <> v_org::text THEN
    RAISE EXCEPTION 'invalid_receipt';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM storage.objects
                  WHERE bucket_id = 'payment-receipts' AND name = p_receipt_path) THEN
    RAISE EXCEPTION 'receipt_not_found';
  END IF;
  IF EXISTS (SELECT 1 FROM public.org_payments
              WHERE org_id = v_org AND status = 'in_review') THEN
    RAISE EXCEPTION 'payment_already_in_review';
  END IF;

  INSERT INTO public.org_payments (org_id, months, amount, receipt_path, submitted_by)
  VALUES (v_org, COALESCE(p_months, 1), p_amount, p_receipt_path, auth.uid())
  RETURNING id INTO v_id;

  UPDATE public.organizations SET billing_status = 'in_review', billing_note = NULL
   WHERE id = v_org
  RETURNING name INTO v_name;

  INSERT INTO public.push_outbox (user_id, title, body, url, tag)
  SELECT pa.user_id, 'Comprobante por revisar',
         v_name || ' subió un pago de ' || COALESCE(p_months, 1) || ' mes(es)',
         '/platform?org=' || v_org, 'org_payment'
    FROM public.platform_admins pa;
  RETURN v_id;
END;
$$;
REVOKE ALL ON FUNCTION public.submit_org_payment(INT, NUMERIC, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_org_payment(INT, NUMERIC, TEXT) TO authenticated;

COMMIT;
