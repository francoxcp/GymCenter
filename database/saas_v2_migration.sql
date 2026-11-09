-- =====================================================================
-- SaaS v2: seguimiento de invitaciones, límite de socios por plan,
-- panel de ingresos, avisos de fin de prueba y limpieza de comprobantes.
--
-- Requiere multitenant_migration.sql aplicado. Idempotente.
-- =====================================================================
BEGIN;

-- ---------------------------------------------------------------------
-- 1. Invitaciones: cuántas veces se abrió el enlace
-- ---------------------------------------------------------------------
ALTER TABLE public.invitations
  ADD COLUMN IF NOT EXISTS views INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_viewed_at TIMESTAMPTZ;

-- La llama la pantalla pública de invitación (sin sesión). Solo suma 1 a
-- una invitación vigente; no devuelve datos.
CREATE OR REPLACE FUNCTION public.track_invitation_view(p_token TEXT)
RETURNS VOID LANGUAGE sql VOLATILE SECURITY DEFINER SET search_path = public AS $$
  UPDATE public.invitations
     SET views = LEAST(views + 1, 100000), last_viewed_at = now()
   WHERE token = upper(trim(p_token))
     AND NOT revoked AND expires_at > now()
     AND (last_viewed_at IS NULL OR last_viewed_at < now() - interval '10 seconds');
$$;
REVOKE ALL ON FUNCTION public.track_invitation_view(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.track_invitation_view(TEXT) TO anon, authenticated;

-- ---------------------------------------------------------------------
-- 2. Límite de socios por plan
-- ---------------------------------------------------------------------
ALTER TABLE public.organizations
  ADD COLUMN IF NOT EXISTS max_members INT CHECK (max_members IS NULL OR max_members > 0);
-- Lo pueden leer los miembros (para mostrar "18 de 30 socios")
GRANT SELECT (max_members) ON public.organizations TO authenticated;

CREATE OR REPLACE FUNCTION public.org_has_room(p_org UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT o.max_members IS NULL
      OR (SELECT count(*) FROM public.users u
           WHERE u.org_id = o.id AND u.role = 'user') < o.max_members
    FROM public.organizations o WHERE o.id = p_org;
$$;
-- Solo la usan funciones internas (no se expone a la app)
REVOKE ALL ON FUNCTION public.org_has_room(UUID) FROM PUBLIC, anon, authenticated;

-- Registro con código: si el gimnasio está lleno, la cuenta queda sin
-- organización (verá "¿Con quién entrenas?") en vez de fallar el registro.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_trainer UUID;
  v_org UUID;
BEGIN
  SELECT id, org_id INTO v_trainer, v_org FROM public.users
   WHERE trainer_code = upper(trim(NEW.raw_user_meta_data->>'trainer_code'))
     AND role IN ('trainer', 'admin')
     AND EXISTS (SELECT 1 FROM public.organizations o
                  WHERE o.id = users.org_id AND o.status = 'active')
   LIMIT 1;
  IF v_org IS NOT NULL AND NOT COALESCE(public.org_has_room(v_org), true) THEN
    v_trainer := NULL;
    v_org := NULL;
  END IF;

  INSERT INTO public.users (id, email, name, role, trainer_id, org_id)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NULLIF(trim(NEW.raw_user_meta_data->>'name'), ''), 'Usuario Nuevo'),
    'user',
    v_trainer,
    v_org
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.link_trainer_by_code(p_code TEXT)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_trainer RECORD;
  v_my_org UUID;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not_authenticated'; END IF;
  v_my_org := public.my_org_id();
  SELECT u.id, u.name, u.org_id INTO v_trainer FROM public.users u
    JOIN public.organizations o ON o.id = u.org_id AND o.status = 'active'
   WHERE u.trainer_code = upper(trim(p_code)) AND u.role IN ('trainer', 'admin');
  IF NOT FOUND OR v_trainer.id = auth.uid()
     OR (v_my_org IS NOT NULL AND v_my_org <> v_trainer.org_id) THEN
    RAISE EXCEPTION 'invalid_trainer_code';
  END IF;
  IF public.is_staff() AND v_my_org IS NOT NULL THEN
    RAISE EXCEPTION 'invalid_trainer_code';
  END IF;
  -- Bloqueo de la organización: evita superar el límite con altas simultáneas
  PERFORM 1 FROM public.organizations WHERE id = v_trainer.org_id FOR UPDATE;
  IF v_my_org IS NULL AND NOT COALESCE(public.org_has_room(v_trainer.org_id), true) THEN
    RAISE EXCEPTION 'member_limit';
  END IF;

  PERFORM set_config('app.trainer_link', '1', true);
  PERFORM set_config('app.org_link', '1', true);
  UPDATE public.users SET org_id = v_trainer.org_id, trainer_id = v_trainer.id
   WHERE id = auth.uid();
  PERFORM set_config('app.trainer_link', '', true);
  PERFORM set_config('app.org_link', '', true);
  RETURN v_trainer.name;
END;
$$;
REVOKE ALL ON FUNCTION public.link_trainer_by_code(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.link_trainer_by_code(TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.accept_invitation(p_token TEXT)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_inv  RECORD;
  v_me   RECORD;
  v_org_name TEXT;
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

  v_new_role := CASE
    WHEN v_inv.role = 'admin' THEN 'admin'
    WHEN v_inv.role = 'trainer' AND v_me.role = 'user' THEN 'trainer'
    ELSE v_me.role END;

  IF v_me.org_id = v_inv.org_id AND v_new_role = v_me.role THEN
    RETURN v_org_name;
  END IF;

  -- Plan lleno: un socio nuevo no entra (entrenadores y dueños sí)
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

  UPDATE public.invitations SET uses = uses + 1 WHERE id = v_inv.id;
  RETURN v_org_name;
END;
$$;
REVOKE ALL ON FUNCTION public.accept_invitation(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_invitation(TEXT) TO authenticated;

-- Plataforma: cambiar plan, cuota y límite de un cliente
CREATE OR REPLACE FUNCTION public.platform_update_org(
  p_org UUID, p_plan TEXT, p_monthly_fee NUMERIC, p_max_members INT
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  UPDATE public.organizations
     SET plan = COALESCE(NULLIF(btrim(p_plan), ''), plan),
         monthly_fee = p_monthly_fee,
         max_members = CASE WHEN p_max_members IS NULL OR p_max_members <= 0
                            THEN NULL ELSE p_max_members END
   WHERE id = p_org;
END;
$$;
REVOKE ALL ON FUNCTION public.platform_update_org(UUID, TEXT, NUMERIC, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_update_org(UUID, TEXT, NUMERIC, INT) TO authenticated;

-- Listado de clientes con plan y límite (reemplaza la versión anterior)
DROP FUNCTION IF EXISTS public.platform_list_orgs();
CREATE FUNCTION public.platform_list_orgs()
RETURNS TABLE(id UUID, name TEXT, kind TEXT, logo_url TEXT, status TEXT,
              billing_status TEXT, billing_note TEXT, paid_until DATE,
              monthly_fee NUMERIC, plan TEXT, max_members INT, in_trial BOOLEAN,
              owner_name TEXT, owner_email TEXT,
              trainers BIGINT, members BIGINT, pending_reviews BIGINT,
              created_at TIMESTAMPTZ)
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
         o.created_at
    FROM public.organizations o
   WHERE public.is_platform_admin()
   ORDER BY (SELECT count(*) FROM public.org_payments p
              WHERE p.org_id = o.id AND p.status = 'in_review') DESC, o.name;
$$;
REVOKE ALL ON FUNCTION public.platform_list_orgs() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_list_orgs() TO authenticated;

-- Alta de cliente con plan y límite (reemplaza la versión de 4 parámetros)
DROP FUNCTION IF EXISTS public.platform_create_org(TEXT, TEXT, NUMERIC, INT);
CREATE OR REPLACE FUNCTION public.platform_create_org(
  p_name TEXT, p_kind TEXT, p_monthly_fee NUMERIC DEFAULT NULL,
  p_trial_days INT DEFAULT 14, p_plan TEXT DEFAULT 'Mensual', p_max_members INT DEFAULT NULL
) RETURNS TABLE(org_id UUID, token TEXT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_org UUID;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.organizations (name, kind, monthly_fee, plan, max_members, paid_until,
                                    billing_status, billing_note, created_by)
  VALUES (btrim(p_name), p_kind, p_monthly_fee, COALESCE(NULLIF(btrim(p_plan), ''), 'Mensual'),
          CASE WHEN p_max_members IS NULL OR p_max_members <= 0 THEN NULL ELSE p_max_members END,
          (now() AT TIME ZONE 'America/Costa_Rica')::date + GREATEST(COALESCE(p_trial_days, 0), 0),
          CASE WHEN COALESCE(p_trial_days, 0) > 0 THEN 'approved' ELSE 'pending' END,
          CASE WHEN COALESCE(p_trial_days, 0) > 0 THEN 'Periodo de prueba' END,
          auth.uid())
  RETURNING id INTO v_org;
  RETURN QUERY SELECT v_org, public.create_invitation('admin', v_org);
END;
$$;
REVOKE ALL ON FUNCTION public.platform_create_org(TEXT, TEXT, NUMERIC, INT, TEXT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_create_org(TEXT, TEXT, NUMERIC, INT, TEXT, INT) TO authenticated;

-- ---------------------------------------------------------------------
-- 3. Panel de ingresos (súper admin)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.platform_stats()
RETURNS TABLE(collected_this_month NUMERIC, collected_last_month NUMERIC,
              expected_monthly NUMERIC, active_orgs BIGINT, in_trial BIGINT,
              expiring_7d BIGINT, pending BIGINT, suspended BIGINT,
              total_members BIGINT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH today AS (SELECT (now() AT TIME ZONE 'America/Costa_Rica')::date AS d),
  paid AS (
    SELECT o.id, EXISTS (SELECT 1 FROM public.org_payments p
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
    COALESCE((SELECT sum(o.monthly_fee) FROM public.organizations o
               WHERE o.status = 'active' AND o.plan <> 'Interno'), 0),
    (SELECT count(*) FROM public.organizations o
      WHERE o.status = 'active' AND o.plan <> 'Interno'),
    (SELECT count(*) FROM paid
       JOIN public.organizations o ON o.id = paid.id
      WHERE NOT paid.has_paid AND o.billing_status = 'approved'),
    (SELECT count(*) FROM public.organizations o, today
      WHERE o.plan <> 'Interno' AND o.paid_until BETWEEN today.d AND today.d + 7),
    (SELECT count(*) FROM public.organizations o
      WHERE o.plan <> 'Interno' AND o.billing_status IN ('pending', 'in_review')),
    (SELECT count(*) FROM public.organizations o WHERE o.status = 'suspended'),
    (SELECT count(*) FROM public.users u WHERE u.role = 'user' AND u.org_id IS NOT NULL)
  WHERE public.is_platform_admin();
$$;
REVOKE ALL ON FUNCTION public.platform_stats() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.platform_stats() TO authenticated;

-- ---------------------------------------------------------------------
-- 4. Avisos diarios: fin de prueba, vencimientos y aviso a la plataforma
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.refresh_org_billing()
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_today DATE := (now() AT TIME ZONE 'America/Costa_Rica')::date;
BEGIN
  -- Avisos al dueño 3 días antes y el día del vencimiento
  INSERT INTO public.push_outbox (user_id, title, body, url, tag, dedupe_key)
  SELECT u.id,
         CASE WHEN trial THEN
                CASE WHEN o.paid_until = v_today THEN 'Tu prueba gratis termina hoy'
                     ELSE 'Tu prueba gratis termina en 3 días' END
              ELSE
                CASE WHEN o.paid_until = v_today THEN 'Tu suscripción vence hoy'
                     ELSE 'Tu suscripción vence en 3 días' END
         END,
         'Sube el comprobante de pago desde Mi gimnasio para seguir sin interrupciones.',
         '/admin/organization', 'org_billing',
         'org:' || o.id || ':' || o.paid_until || ':' || (o.paid_until - v_today) || ':' || u.id
    FROM (SELECT o.*, NOT EXISTS (SELECT 1 FROM public.org_payments p
                                   WHERE p.org_id = o.id AND p.status = 'approved') AS trial
            FROM public.organizations o) o
    JOIN public.users u ON u.org_id = o.id AND u.role = 'admin'
   WHERE o.plan <> 'Interno'
     AND o.billing_status = 'approved'
     AND o.paid_until IN (v_today, v_today + 3)
  ON CONFLICT (dedupe_key) DO NOTHING;

  -- Aviso a la plataforma de los que vencen hoy (para dar seguimiento)
  INSERT INTO public.push_outbox (user_id, title, body, url, tag, dedupe_key)
  SELECT pa.user_id,
         'Clientes que vencen hoy: ' || count(*),
         string_agg(o.name, ', ' ORDER BY o.name),
         '/platform', 'platform_billing',
         'platform:' || v_today || ':' || pa.user_id
    FROM public.organizations o CROSS JOIN public.platform_admins pa
   WHERE o.plan <> 'Interno' AND o.paid_until = v_today
   GROUP BY pa.user_id
  ON CONFLICT (dedupe_key) DO NOTHING;

  -- Vencidos → pago pendiente
  UPDATE public.organizations
     SET billing_status = 'pending',
         billing_note = CASE WHEN billing_note = 'Periodo de prueba'
                             THEN 'Terminó la prueba gratis' ELSE 'Suscripción vencida' END
   WHERE billing_status = 'approved' AND paid_until < v_today AND plan <> 'Interno';
END;
$$;
REVOKE ALL ON FUNCTION public.refresh_org_billing() FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------
-- 5. Limpieza de comprobantes revisados hace más de 6 meses
--    (el borrado del archivo lo hace la función send-push con la API de
--    Storage; aquí solo se marca)
-- ---------------------------------------------------------------------
ALTER TABLE public.org_payments
  ADD COLUMN IF NOT EXISTS receipt_deleted_at TIMESTAMPTZ;

-- El dueño puede listar sus logos (para borrar el anterior al subir uno nuevo)
DROP POLICY IF EXISTS org_logos_select ON storage.objects;
CREATE POLICY org_logos_select ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'org-logos' AND public.is_admin()
         AND (storage.foldername(name))[1] = public.my_org_id()::text);

COMMIT;
