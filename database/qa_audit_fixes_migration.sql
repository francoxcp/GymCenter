-- =============================================================================
-- GYMLAB · Correcciones de la auditoría QA (noviembre 2026)
-- Idempotente: se puede ejecutar más de una vez.
--
--  1. Borrar una cuenta (entrenador) ya no borra sus rutinas ni el historial
--     de sus socios: las rutinas y los socios pasan al dueño del gimnasio.
--  2. Borrar una rutina conserva las sesiones ya hechas (con su nombre).
--  3. El dueño no puede borrar su propia cuenta ni quitarse el rol.
--  4. El contador de entrenos se recalcula en el servidor (sin duplicados
--     ni manipulación desde el cliente).
--  5. El socio solo ve las rutinas que tiene asignadas y no puede crear
--     rutinas; solo registra series de rutinas que puede ver.
--  6. search_path fijo en funciones de trigger.
--  7. Rendimiento: índices de claves foráneas, índices y políticas
--     duplicadas, auth.uid() evaluado una sola vez por consulta.
--
--  Al borrar a un entrenador: sus rutinas, socios y chats pasan al dueño;
--  sus comentarios en sesiones quedan como "cuenta eliminada".
-- =============================================================================

begin;

-- ─── 1. Al borrar un usuario, sus rutinas y socios pasan al dueño ───────────
create or replace function public.reassign_before_user_delete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org   uuid;
  v_owner uuid;
begin
  select org_id into v_org from public.users where id = OLD.id;
  if v_org is not null then
    select id into v_owner from public.users
     where org_id = v_org and role = 'admin' and id <> OLD.id
     order by created_at
     limit 1;
  end if;

  -- Permite cambiar created_by (workouts_org_guard lo bloquea por defecto)
  perform set_config('app.workout_reassign', '1', true);
  update public.workouts set created_by = v_owner where created_by = OLD.id;

  -- app.workout_reassign sigue activo hasta el fin de la transacción a
  -- propósito: así el ON DELETE SET NULL de workouts_created_by_fkey también
  -- puede actuar (solo dura lo que dura este borrado).

  if v_owner is not null then
    -- Permite reasignar el entrenador (users_guard lo bloquea por defecto)
    perform set_config('app.trainer_link', '1', true);
    update public.users set trainer_id = v_owner where trainer_id = OLD.id;
    perform set_config('app.trainer_link', '', true);

    -- Los chats con sus socios pasan al dueño (no se borran)
    update public.direct_messages
       set trainer_id = v_owner,
           sender_id = case when sender_id = OLD.id then v_owner else sender_id end
     where trainer_id = OLD.id;
  end if;
  return OLD;
end;
$$;

revoke execute on function public.reassign_before_user_delete() from public, anon, authenticated;

drop trigger if exists gymlab_before_user_delete on auth.users;
create trigger gymlab_before_user_delete
  before delete on auth.users
  for each row execute function public.reassign_before_user_delete();

-- Red de seguridad: si no hay dueño al que pasarlas, la rutina queda
-- sin autor (plantilla del gimnasio) en vez de borrarse. Funciona porque
-- gymlab_before_user_delete deja activo app.workout_reassign.
alter table public.workouts drop constraint if exists workouts_created_by_fkey;
alter table public.workouts
  add constraint workouts_created_by_fkey
  foreign key (created_by) references auth.users(id) on delete set null;

create or replace function public.workouts_org_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    if auth.uid() is not null then
      NEW.org_id := public.my_org_id();
    end if;
  else
    NEW.org_id := OLD.org_id;
    if coalesce(current_setting('app.workout_reassign', true), '') <> '1' then
      NEW.created_by := OLD.created_by;
    end if;
  end if;
  return NEW;
end;
$$;

-- ─── 2. Borrar una rutina conserva el historial ─────────────────────────────
alter table public.workout_sessions add column if not exists workout_name text;

update public.workout_sessions s
   set workout_name = w.name
  from public.workouts w
 where w.id = s.workout_id
   and s.workout_name is null;

alter table public.workout_sessions alter column workout_id drop not null;
alter table public.workout_sessions drop constraint if exists workout_sessions_workout_id_fkey;
alter table public.workout_sessions
  add constraint workout_sessions_workout_id_fkey
  foreign key (workout_id) references public.workouts(id) on delete set null;

create or replace function public.session_fill_workout_name()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if NEW.workout_name is null and NEW.workout_id is not null then
    -- Solo si quien entrena puede ver la rutina (no revela nombres ajenos)
    select w.name into NEW.workout_name
      from public.workouts w
     where w.id = NEW.workout_id
       and (auth.uid() is null or public.can_view_workout(w.id, w.created_by));
  end if;
  return NEW;
end;
$$;

revoke execute on function public.session_fill_workout_name() from public, anon, authenticated;

drop trigger if exists session_fill_workout_name on public.workout_sessions;
create trigger session_fill_workout_name
  before insert on public.workout_sessions
  for each row execute function public.session_fill_workout_name();

-- Comentarios de una cuenta borrada: se conservan sin autor
alter table public.session_comments alter column author_id drop not null;
alter table public.session_comments drop constraint if exists session_comments_author_id_fkey;
alter table public.session_comments
  add constraint session_comments_author_id_fkey
  foreign key (author_id) references public.users(id) on delete set null;

-- ─── 3. El dueño no se borra ni se quita el rol ─────────────────────────────
create or replace function public.delete_user_account(user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is distinct from user_id then
    raise exception 'Unauthorized: you can only delete your own account';
  end if;
  if exists (select 1 from public.users u
              where u.id = delete_user_account.user_id
                and u.role = 'admin') then
    raise exception 'owner_cannot_delete' using errcode = '42501';
  end if;
  -- Borra en cascada todos sus datos (public.users, sesiones, medidas…).
  -- gymlab_before_user_delete pasa antes sus rutinas y socios al dueño.
  delete from auth.users where id = delete_user_account.user_id;
end;
$$;

-- users_guard: igual que antes + el dueño no se quita el rol a sí mismo +
-- completed_workouts solo lo cambia el contador del servidor.
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

-- ─── 4. Contador de entrenos calculado en el servidor ──────────────────────
create or replace function public.update_user_completed_workouts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := coalesce(NEW.user_id, OLD.user_id);
begin
  -- Borrado en cascada de la cuenta: no hay contador que actualizar
  if TG_OP = 'DELETE' and not exists (select 1 from public.users where id = v_user) then
    return null;
  end if;
  perform set_config('app.counter', '1', true);
  update public.users
     set completed_workouts = (select count(*) from public.workout_sessions
                                where user_id = v_user)
   where id = v_user;
  perform set_config('app.counter', '', true);
  return null;
end;
$$;

revoke execute on function public.update_user_completed_workouts() from public, anon, authenticated;

drop trigger if exists trigger_update_completed_workouts on public.workout_sessions;
create trigger trigger_update_completed_workouts
  after insert or delete on public.workout_sessions
  for each row execute function public.update_user_completed_workouts();

-- Corrige los contadores actuales (auth.uid() es NULL aquí: el guard no actúa)
update public.users u
   set completed_workouts = c.n
  from (select u2.id, (select count(*) from public.workout_sessions s
                        where s.user_id = u2.id) as n
          from public.users u2) c
 where c.id = u.id
   and u.completed_workouts is distinct from c.n;

-- ─── 5. Qué rutinas ve y crea un socio ─────────────────────────────────────
-- El socio ve solo lo que tiene asignado (rutina actual o plan semanal).
-- Dueño y entrenadores siguen viendo las plantillas del gimnasio.
create or replace function public.can_view_workout(p_workout uuid, p_created_by uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null and (
       p_created_by = auth.uid()
    or exists (
         select 1 from public.workouts w
          where w.id = p_workout
            and w.org_id is not null
            and w.org_id = public.my_active_org_id()
            and (
                 public.is_admin()
              or (public.is_staff() and (
                     p_created_by is null
                  or exists (select 1 from public.users c
                              where c.id = p_created_by and c.role = 'admin')))
              or exists (select 1 from public.users me
                          where me.id = auth.uid() and me.assigned_workout_id = p_workout)
              or exists (select 1 from public.user_workout_schedule s
                          where s.workout_id = p_workout
                            and (s.user_id = auth.uid() or public.can_manage_user(s.user_id)))
            ))
  );
$$;

drop policy if exists workouts_insert on public.workouts;
create policy workouts_insert on public.workouts
  for insert
  with check (created_by = (select auth.uid()) and public.is_staff());

-- Registrar series solo de rutinas que el usuario puede ver.
-- Búsqueda por clave primaria (workout_id es texto en exercise_set_logs).
create or replace function public.can_log_workout(p_workout text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.workouts w
     where w.id = case when p_workout ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
                       then p_workout::uuid end
       and public.can_view_workout(w.id, w.created_by)
  );
$$;

revoke execute on function public.can_log_workout(text) from public, anon;
grant execute on function public.can_log_workout(text) to authenticated;

drop policy if exists esl_insert on public.exercise_set_logs;
create policy esl_insert on public.exercise_set_logs
  for insert
  with check (
    user_id = (select auth.uid())
    and public.can_log_workout(workout_id)
  );

-- ─── 6. search_path fijo en funciones de trigger ───────────────────────────
alter function public.update_updated_at_column() set search_path = public;
alter function public.update_workout_exercise_count() set search_path = public;
alter function public.update_workout_progress_updated_at() set search_path = public;

-- ─── 7. Rendimiento ────────────────────────────────────────────────────────
-- Índices duplicados (se conserva el otro, idéntico)
drop index if exists public.idx_body_measurements_date;
drop index if exists public.idx_exercise_set_logs_logged_at;
drop index if exists public.idx_workout_sessions_completed;

-- Claves foráneas sin índice
create index if not exists idx_user_achievements_achievement on public.user_achievements(achievement_id);
create index if not exists idx_workout_progress_workout on public.workout_progress(workout_id);
create index if not exists idx_workouts_created_by on public.workouts(created_by);
create index if not exists idx_schedule_workout on public.user_workout_schedule(workout_id);
create index if not exists idx_session_comments_author on public.session_comments(author_id);
create index if not exists idx_membership_payments_created_by on public.membership_payments(created_by);
create index if not exists idx_organizations_created_by on public.organizations(created_by);
create index if not exists idx_invitations_trainer on public.invitations(trainer_id);
create index if not exists idx_invitations_created_by on public.invitations(created_by);
create index if not exists idx_org_payments_submitted_by on public.org_payments(submitted_by);
create index if not exists idx_org_payments_reviewed_by on public.org_payments(reviewed_by);
create index if not exists idx_member_notes_author on public.member_notes(author_id);
create index if not exists idx_direct_messages_sender on public.direct_messages(sender_id);
create index if not exists idx_direct_messages_session on public.direct_messages(session_id);
create index if not exists idx_body_measurements_recorded_by on public.body_measurements(recorded_by);
-- (workout_sessions.workout_id ya tiene idx_workout_sessions_workout_id)
drop index if exists public.idx_workout_sessions_workout;

-- Políticas duplicadas en user_preferences (las up_* ya cubren lo mismo)
drop policy if exists user_preferences_insert_own on public.user_preferences;
drop policy if exists user_preferences_select_own on public.user_preferences;
drop policy if exists user_preferences_update_own on public.user_preferences;
drop policy if exists up_insert on public.user_preferences;
create policy up_insert on public.user_preferences
  for insert with check ((select auth.uid()) = user_id);
drop policy if exists up_update on public.user_preferences;
create policy up_update on public.user_preferences
  for update
  using ((select auth.uid()) = user_id or public.owns_member(user_id))
  with check ((select auth.uid()) = user_id or public.owns_member(user_id));

-- personal_records: pr_write (ALL) se solapaba con pr_select en lecturas
drop policy if exists pr_write on public.personal_records;
drop policy if exists pr_insert on public.personal_records;
drop policy if exists pr_update on public.personal_records;
drop policy if exists pr_delete on public.personal_records;
create policy pr_insert on public.personal_records
  for insert with check (user_id = (select auth.uid()));
create policy pr_update on public.personal_records
  for update using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy pr_delete on public.personal_records
  for delete using (user_id = (select auth.uid()));

-- auth.uid() → (select auth.uid()): se evalúa una vez por consulta y no por
-- fila. Solo toca políticas que aún no están envueltas (idempotente).
do $$
declare
  p record;
begin
  for p in
    select schemaname, tablename, policyname, qual, with_check
      from pg_policies
     where schemaname = 'public'
  loop
    if p.qual is not null
       and p.qual like '%auth.uid()%'
       and p.qual not like '%SELECT auth.uid()%' then
      execute format('alter policy %I on %I.%I using (%s)',
                     p.policyname, p.schemaname, p.tablename,
                     replace(p.qual, 'auth.uid()', '(select auth.uid())'));
    end if;
    if p.with_check is not null
       and p.with_check like '%auth.uid()%'
       and p.with_check not like '%SELECT auth.uid()%' then
      execute format('alter policy %I on %I.%I with check (%s)',
                     p.policyname, p.schemaname, p.tablename,
                     replace(p.with_check, 'auth.uid()', '(select auth.uid())'));
    end if;
  end loop;
end;
$$;

-- Funciones de trigger: no deben poder llamarse por la API
revoke execute on function public.notify_session_comment() from public, anon, authenticated;
revoke execute on function public.notify_session_done() from public, anon, authenticated;

commit;
