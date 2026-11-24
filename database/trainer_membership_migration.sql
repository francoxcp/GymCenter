-- =============================================================
-- Membresías: el entrenador puede cobrar a SUS socios
-- - El dueño sigue pudiendo cobrar a todos los socios de su gimnasio.
-- - Un entrenador puede registrar pagos, corregir el vencimiento y ver el
--   historial solo de los socios vinculados a él (users.trainer_id).
-- Idempotente: se puede ejecutar varias veces.
-- =============================================================

-- ¿Quién puede cobrar a este socio?
CREATE OR REPLACE FUNCTION public.can_charge_member(p_user uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.owns_member(p_user)
      OR EXISTS (
           SELECT 1
             FROM public.users m
             JOIN public.users me ON me.id = auth.uid()
            WHERE m.id = p_user
              AND m.role = 'user'
              AND m.trainer_id = auth.uid()
              AND me.role = 'trainer'
              AND m.org_id IS NOT DISTINCT FROM me.org_id
         );
$$;

REVOKE ALL ON FUNCTION public.can_charge_member(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.can_charge_member(uuid) TO authenticated;

-- Registrar pago (dueño o entrenador del socio)
CREATE OR REPLACE FUNCTION public.renew_membership(
  p_user uuid, p_plan text, p_months integer, p_amount numeric DEFAULT NULL::numeric)
RETURNS date
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE := (now() AT TIME ZONE 'America/Costa_Rica')::date;
  v_end   DATE;
  v_start DATE;
  v_new   DATE;
BEGIN
  IF NOT public.can_charge_member(p_user) THEN
    RAISE EXCEPTION 'Solo el dueño o el entrenador del socio pueden registrar membresías' USING ERRCODE = '42501';
  END IF;
  IF p_months IS NULL OR p_months < 1 OR p_months > 24 THEN
    RAISE EXCEPTION 'Meses inválidos';
  END IF;
  IF p_plan IS NULL OR char_length(btrim(p_plan)) = 0 OR char_length(p_plan) > 40 THEN
    RAISE EXCEPTION 'Plan inválido';
  END IF;
  IF p_amount IS NOT NULL AND (p_amount < 0 OR p_amount > 100000000) THEN
    RAISE EXCEPTION 'Monto inválido';
  END IF;

  SELECT membership_end INTO v_end FROM public.users WHERE id = p_user FOR UPDATE;
  v_start := CASE WHEN v_end IS NOT NULL AND v_end >= v_today THEN v_end + 1 ELSE v_today END;
  v_new := (v_start + make_interval(months => p_months))::date - 1;

  -- Permiso para que users_guard deje pasar el cambio de membresía
  PERFORM set_config('app.membership', '1', true);
  UPDATE public.users
     SET membership_plan = btrim(p_plan),
         membership_start = CASE WHEN v_end IS NOT NULL AND v_end >= v_today
                                 THEN COALESCE(membership_start, v_start) ELSE v_start END,
         membership_end = v_new
   WHERE id = p_user;
  PERFORM set_config('app.membership', '', true);

  INSERT INTO public.membership_payments
    (user_id, plan, amount, period_start, period_end, created_by)
  VALUES (p_user, btrim(p_plan), p_amount, v_start, v_new, auth.uid());
  RETURN v_new;
END;
$$;

-- Corregir la fecha de vencimiento a mano (dueño o entrenador del socio)
CREATE OR REPLACE FUNCTION public.set_membership_end(p_user uuid, p_end date)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.can_charge_member(p_user) THEN
    RAISE EXCEPTION 'Solo el dueño o el entrenador del socio pueden cambiar la membresía' USING ERRCODE = '42501';
  END IF;
  PERFORM set_config('app.membership', '1', true);
  UPDATE public.users SET membership_end = p_end WHERE id = p_user;
  PERFORM set_config('app.membership', '', true);
END;
$$;

REVOKE ALL ON FUNCTION public.set_membership_end(uuid, date) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.set_membership_end(uuid, date) TO authenticated;

-- users_guard: igual que antes, pero respeta el permiso 'app.membership'
-- que solo activan las dos funciones de arriba tras validar el permiso.
CREATE OR REPLACE FUNCTION public.users_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
declare
  v_trainer_org uuid;
begin
  if auth.uid() is not null then
    if TG_OP = 'INSERT' then
      NEW.role := 'user';
      NEW.trainer_id := null;
      NEW.trainer_code := null;
      NEW.assigned_workout_id := null;
      NEW.membership_plan := null;
      NEW.membership_start := null;
      NEW.membership_end := null;
      NEW.org_id := null;
      NEW.completed_workouts := 0;
    else
      if coalesce(current_setting('app.org_link', true), '') <> '1' then
        NEW.org_id := OLD.org_id;
      end if;
      if coalesce(current_setting('app.counter', true), '') <> '1' then
        NEW.completed_workouts := OLD.completed_workouts;
      end if;
      NEW.photo_url := OLD.photo_url;
      if OLD.id = auth.uid() then
        NEW.name := OLD.name;
      end if;
      if not public.is_admin()
         and coalesce(current_setting('app.invite_role', true), '') <> '1' then
        NEW.role := OLD.role;
        if coalesce(current_setting('app.trainer_link', true), '') <> '1' then
          NEW.trainer_id := OLD.trainer_id;
          NEW.trainer_code := OLD.trainer_code;
        end if;
        if OLD.id = auth.uid() then
          NEW.assigned_workout_id := OLD.assigned_workout_id;
        end if;
        if coalesce(current_setting('app.membership', true), '') <> '1' then
          NEW.membership_plan := OLD.membership_plan;
          NEW.membership_start := OLD.membership_start;
          NEW.membership_end := OLD.membership_end;
        end if;
      elsif OLD.id = auth.uid() and OLD.role = 'admin' then
        NEW.role := OLD.role;
      end if;
    end if;
  end if;

  if auth.uid() is not null and NEW.trainer_id is not null
     and (TG_OP = 'INSERT' or NEW.trainer_id is distinct from OLD.trainer_id) then
    select org_id into v_trainer_org from public.users where id = NEW.trainer_id;
    if v_trainer_org is distinct from NEW.org_id then
      raise exception 'trainer_other_org' using errcode = '42501';
    end if;
  end if;

  if NEW.role in ('trainer', 'admin') and NEW.trainer_code is null then
    NEW.trainer_code := public.gen_trainer_code();
  elsif NEW.role = 'user' then
    NEW.trainer_code := null;
  end if;
  if NEW.trainer_id = NEW.id then
    NEW.trainer_id := null;
  end if;
  return NEW;
end;
$$;

-- Historial de pagos: el socio ve los suyos; dueño y entrenador los de quien cobran
DROP POLICY IF EXISTS mp_select ON public.membership_payments;
CREATE POLICY mp_select ON public.membership_payments FOR SELECT
  USING (user_id = (SELECT auth.uid()) OR public.can_charge_member(user_id));

-- Borrar un pago sigue siendo solo del dueño
DROP POLICY IF EXISTS mp_delete ON public.membership_payments;
CREATE POLICY mp_delete ON public.membership_payments FOR DELETE
  USING (public.owns_member(user_id));
