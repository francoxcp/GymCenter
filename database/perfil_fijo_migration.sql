-- =============================================================================
-- GYMLAB · Perfil fijo y endurecimiento
-- Idempotente. Ejecutar en Supabase → SQL Editor.
--
--  1. Sin fotos de perfil: el almacenamiento profile-photos pasa a privado,
--     no admite subidas nuevas y se limpian las referencias en users.
--  2. Nombre y apellido fijos: cada persona ya no puede cambiar su nombre.
--     El dueño o el entrenador del socio sí pueden corregir errores.
--  3. exercise_library_guard (función de trigger) no se puede llamar por la API.
-- =============================================================================

begin;

-- ─── 1. Fotos de perfil ────────────────────────────────────────────────────
update storage.buckets set public = false where id = 'profile-photos';
drop policy if exists "Users can upload own profile photos" on storage.objects;
drop policy if exists "Users can update own profile photos" on storage.objects;
-- Se conservan: lectura acotada y borrado propio (al eliminar la cuenta).
update public.users set photo_url = null where photo_url is not null;

-- ─── 2. Nombre fijo (users_guard actual + 2 reglas) ─────────────────────────
create or replace function public.users_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
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
      -- Nadie mueve usuarios entre organizaciones salvo las funciones de
      -- invitación / vínculo por código.
      if coalesce(current_setting('app.org_link', true), '') <> '1' then
        NEW.org_id := OLD.org_id;
      end if;
      if coalesce(current_setting('app.counter', true), '') <> '1' then
        NEW.completed_workouts := OLD.completed_workouts;
      end if;
      -- Sin fotos de perfil: nadie las cambia desde la app
      NEW.photo_url := OLD.photo_url;
      -- Nombre y apellido fijos para la propia persona (el dueño o su
      -- entrenador pueden corregir un error de escritura de un socio)
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
        NEW.membership_plan := OLD.membership_plan;
        NEW.membership_start := OLD.membership_start;
        NEW.membership_end := OLD.membership_end;
      elsif OLD.id = auth.uid() and OLD.role = 'admin' then
        -- El dueño no puede dejar el gimnasio sin dueño
        NEW.role := OLD.role;
      end if;
    end if;
  end if;

  -- El entrenador asignado debe ser de la misma organización
  -- (desde el panel SQL / service role, auth.uid() es NULL: sin restricción)
  -- Solo si cambia el entrenador: el contador de entrenos y otras
  -- actualizaciones no deben fallar por datos heredados.
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

-- ─── 3. Función de trigger fuera de la API ────────────────────────────────
do $$
begin
  if to_regprocedure('public.exercise_library_guard()') is not null then
    revoke execute on function public.exercise_library_guard() from public, anon, authenticated;
  end if;
end;
$$;

commit;
