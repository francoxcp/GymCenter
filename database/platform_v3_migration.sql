-- =====================================================================
-- GYMLAB · Plataforma v3: administrar clientes (gimnasios y entrenadores
-- independientes) de forma más simple.
--   1. platform_list_orgs: + cliente interno, teléfono del dueño e
--      invitación de dueño pendiente (código y vencimiento).
--   2. platform_stats: números coherentes (sin internos ni suspendidos
--      en "en prueba" y "vencen en 7 días").
--   3. platform_register_payment: pago en efectivo / SINPE registrado a mano.
--   4. platform_extend_days: extender prueba o suscripción N días.
--   5. platform_org_team: dueño y entrenadores de un cliente.
-- Solo el administrador de la plataforma puede usarlas (is_platform_admin).
-- Idempotente: se puede ejecutar más de una vez.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Listado de clientes
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.platform_list_orgs();
CREATE FUNCTION public.platform_list_orgs()
RETURNS TABLE(id UUID, name TEXT, kind TEXT, logo_url TEXT, status TEXT,
              billing_status TEXT, billing_note TEXT, paid_until DATE,
              monthly_fee NUMERIC, plan TEXT, max_members INT, in_trial BOOLEAN,
              owner_name TEXT, owner_email TEXT,
              trainers BIGINT, members BIGINT, pending_reviews BIGINT,
              created_at TIMESTAMPTZ, last_activity TIMESTAMPTZ,
              sessions_30d BIGINT,
              is_internal BOOLEAN, owner_phone TEXT,
              invite_token TEXT, invite_expires_at TIMESTAMPTZ)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT o.id, o.name, o.kind, o.logo_url, o.status, o.billing_status, o.billing_note,
         o.paid_until, o.monthly_fee, o.plan, o.max_members,
         NOT EXISTS (SELECT 1 FROM public.org_payments p
                      WHERE p.org_id = o.id AND p.status = 'approved')
           AND o.plan <> 'Interno',
         ow.name, ow.email,
         (SELECT count(*) FROM public.users u WHERE u.org_id = o.id AND u.role = 'trainer'),
         (SELECT count(*) FROM public.users u WHERE u.org_id = o.id AND u.role = 'user'),
         (SELECT count(*) FROM public.org_payments p WHERE p.org_id = o.id AND p.status = 'in_review'),
         o.created_at,
         (SELECT max(s.completed_at) FROM public.workout_sessions s
            JOIN public.users u ON u.id = s.user_id WHERE u.org_id = o.id),
         (SELECT count(*) FROM public.workout_sessions s
            JOIN public.users u ON u.id = s.user_id
           WHERE u.org_id = o.id AND s.completed_at > now() - interval '30 days'),
         o.plan = 'Interno',
         ow.phone,
         inv.token, inv.expires_at
    FROM public.organizations o
    LEFT JOIN LATERAL (
      SELECT u.name, u.email, u.phone FROM public.users u
       WHERE u.org_id = o.id AND u.role = 'admin'
       ORDER BY u.created_at LIMIT 1) ow ON true
    -- Invitación de dueño todavía usable (solo importa si aún no hay dueño)
    LEFT JOIN LATERAL (
      SELECT i.token, i.expires_at FROM public.invitations i
       WHERE i.org_id = o.id AND i.role = 'admin' AND NOT i.revoked
         AND i.uses < i.max_uses AND i.expires_at > now()
       ORDER BY i.created_at DESC LIMIT 1) inv ON ow.name IS NULL
   WHERE public.is_platform_admin()
   ORDER BY (o.plan = 'Interno'),
            (SELECT count(*) FROM public.org_payments p
              WHERE p.org_id = o.id AND p.status = 'in_review') DESC, o.name;
$$;
REVOKE ALL ON FUNCTION public.platform_list_orgs() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_list_orgs() TO authenticated;

-- ---------------------------------------------------------------------
-- 2. Resumen: sin clientes internos y sin suspendidos donde no aplica
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.platform_stats()
RETURNS TABLE(collected_this_month NUMERIC, collected_last_month NUMERIC,
              expected_monthly NUMERIC, active_orgs BIGINT, in_trial BIGINT,
              expiring_7d BIGINT, pending BIGINT, suspended BIGINT,
              total_members BIGINT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH today AS (SELECT (now() AT TIME ZONE 'America/Costa_Rica')::date AS d),
  clients AS (
    SELECT o.*, EXISTS (SELECT 1 FROM public.org_payments p
                         WHERE p.org_id = o.id AND p.status = 'approved') AS has_paid
      FROM public.organizations o WHERE o.plan <> 'Interno'
  )
  SELECT
    COALESCE((SELECT sum(p.amount) FROM public.org_payments p, today
               WHERE p.status = 'approved'
                 AND date_trunc('month', p.reviewed_at AT TIME ZONE 'America/Costa_Rica')
                     = date_trunc('month', today.d)), 0),
    COALESCE((SELECT sum(p.amount) FROM public.org_payments p, today
               WHERE p.status = 'approved'
                 AND date_trunc('month', p.reviewed_at AT TIME ZONE 'America/Costa_Rica')
                     = date_trunc('month', today.d) - interval '1 month'), 0),
    COALESCE((SELECT sum(c.monthly_fee) FROM clients c WHERE c.status = 'active'), 0),
    (SELECT count(*) FROM clients c WHERE c.status = 'active'),
    (SELECT count(*) FROM clients c WHERE c.status = 'active' AND NOT c.has_paid),
    (SELECT count(*) FROM clients c, today
      WHERE c.status = 'active' AND c.paid_until BETWEEN today.d AND today.d + 7),
    (SELECT count(*) FROM clients c
      WHERE c.status = 'active' AND c.billing_status IN ('pending', 'in_review')),
    (SELECT count(*) FROM clients c WHERE c.status = 'suspended'),
    -- Socios de clientes (sin el gimnasio interno)
    (SELECT count(*) FROM public.users u JOIN clients c ON c.id = u.org_id
      WHERE u.role = 'user')
  WHERE public.is_platform_admin();
$$;
REVOKE ALL ON FUNCTION public.platform_stats() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_stats() TO authenticated;

-- ---------------------------------------------------------------------
-- 3. Pago registrado a mano (efectivo, SINPE, transferencia)
--    Queda como pago aprobado sin archivo (receipt_path = 'manual/<uuid>';
--    la ruta es única por el índice uq_org_payments_receipt).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.platform_register_payment(
  p_org UUID, p_months INT, p_amount NUMERIC DEFAULT NULL, p_note TEXT DEFAULT NULL
) RETURNS DATE LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_today DATE := (now() AT TIME ZONE 'America/Costa_Rica')::date;
  v_paid  DATE;
  v_start DATE;
  v_end   DATE;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  IF p_months IS NULL OR p_months < 1 OR p_months > 12 THEN
    RAISE EXCEPTION 'invalid_months';
  END IF;
  IF p_amount IS NOT NULL AND p_amount < 0 THEN
    RAISE EXCEPTION 'invalid_amount';
  END IF;

  SELECT paid_until INTO v_paid FROM public.organizations WHERE id = p_org FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'org_not_found'; END IF;
  v_start := CASE WHEN v_paid IS NOT NULL AND v_paid >= v_today THEN v_paid + 1 ELSE v_today END;
  v_end := (v_start + make_interval(months => p_months))::date - 1;

  INSERT INTO public.org_payments (org_id, months, amount, receipt_path, status,
                                   review_comment, period_start, period_end,
                                   submitted_by, reviewed_by, reviewed_at,
                                   receipt_deleted_at)
  VALUES (p_org, p_months, p_amount, 'manual/' || gen_random_uuid(), 'approved',
          left(NULLIF(btrim(p_note), ''), 500), v_start, v_end,
          auth.uid(), auth.uid(), now(),
          now());  -- sin archivo: la limpieza de comprobantes lo ignora

  UPDATE public.organizations
     SET paid_until = v_end, billing_note = NULL, status = 'active',
         -- Si queda un comprobante por revisar, se sigue viendo "en revisión"
         billing_status = CASE WHEN EXISTS (SELECT 1 FROM public.org_payments p
                                 WHERE p.org_id = p_org AND p.status = 'in_review')
                             THEN 'in_review' ELSE 'approved' END
   WHERE id = p_org;

  INSERT INTO public.push_outbox (user_id, title, body, url, tag)
  SELECT u.id, 'Pago registrado',
         'Tu suscripción está al día hasta el ' || to_char(v_end, 'DD/MM/YYYY'),
         '/admin/organization', 'org_payment'
    FROM public.users u
   WHERE u.org_id = p_org AND u.role = 'admin';

  RETURN v_end;
END;
$$;
REVOKE ALL ON FUNCTION public.platform_register_payment(UUID, INT, NUMERIC, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_register_payment(UUID, INT, NUMERIC, TEXT) TO authenticated;

-- ---------------------------------------------------------------------
-- 4. Extender prueba o suscripción N días (cortesía, demora del cliente)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.platform_extend_days(p_org UUID, p_days INT)
RETURNS DATE LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_today DATE := (now() AT TIME ZONE 'America/Costa_Rica')::date;
  v_end   DATE;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  IF p_days IS NULL OR p_days < 1 OR p_days > 90 THEN
    RAISE EXCEPTION 'invalid_days';
  END IF;

  UPDATE public.organizations
     SET paid_until = GREATEST(COALESCE(paid_until, v_today), v_today) + p_days,
         status = 'active',
         billing_status = CASE WHEN EXISTS (SELECT 1 FROM public.org_payments p
                                 WHERE p.org_id = p_org AND p.status = 'in_review')
                             THEN 'in_review' ELSE 'approved' END
   WHERE id = p_org
  RETURNING paid_until INTO v_end;
  IF v_end IS NULL THEN RAISE EXCEPTION 'org_not_found'; END IF;

  INSERT INTO public.push_outbox (user_id, title, body, url, tag)
  SELECT u.id, 'Tienes más días',
         'Tu acceso sigue activo hasta el ' || to_char(v_end, 'DD/MM/YYYY'),
         '/admin/organization', 'org_billing'
    FROM public.users u
   WHERE u.org_id = p_org AND u.role = 'admin';

  RETURN v_end;
END;
$$;
REVOKE ALL ON FUNCTION public.platform_extend_days(UUID, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_extend_days(UUID, INT) TO authenticated;

-- ---------------------------------------------------------------------
-- 5. Equipo de un cliente: dueño y entrenadores, con sus socios
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.platform_org_team(p_org UUID)
RETURNS TABLE(name TEXT, role TEXT, email TEXT, phone TEXT, members BIGINT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.name, u.role, u.email, u.phone,
         (SELECT count(*) FROM public.users m
           WHERE m.trainer_id = u.id AND m.role = 'user')
    FROM public.users u
   WHERE public.is_platform_admin()
     AND u.org_id = p_org AND u.role IN ('admin', 'trainer')
   ORDER BY (u.role = 'admin') DESC, u.name;
$$;
REVOKE ALL ON FUNCTION public.platform_org_team(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_org_team(UUID) TO authenticated;
