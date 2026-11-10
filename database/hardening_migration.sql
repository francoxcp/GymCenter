-- =============================================================================
-- GYMLAB · Endurecimiento (avisos del asesor de seguridad de Supabase)
-- Idempotente. Ejecutar en Supabase → SQL Editor.
--
--  1. Apaga la API GraphQL: la app usa la API REST y GraphQL listaba los
--     nombres de las tablas a cualquiera.
--  2. Mueve pg_net fuera del esquema público (sus funciones siguen en el
--     esquema net; los avisos push no cambian).
--  3. Tablas internas (solo las usa el servidor): política explícita que
--     deniega todo acceso desde la app, para dejar clara la intención.
--
--  Protección de contraseñas filtradas: no se activa por SQL. Panel →
--  Authentication → Sign In / Providers → Email → "Prevent use of leaked
--  passwords".
-- =============================================================================

-- 1. GraphQL desactivado
drop extension if exists pg_graphql;

-- 2. pg_net al esquema extensions (no admite SET SCHEMA: se recrea)
do $$
begin
  if exists (select 1 from pg_extension
              where extname = 'pg_net'
                and extnamespace = 'public'::regnamespace) then
    drop extension pg_net;
  end if;
end;
$$;
create extension if not exists pg_net with schema extensions;

-- 3. Tablas solo de servidor (service role ignora RLS)
drop policy if exists platform_admins_no_client on public.platform_admins;
create policy platform_admins_no_client on public.platform_admins
  for all to anon, authenticated using (false) with check (false);

drop policy if exists push_config_no_client on public.push_config;
create policy push_config_no_client on public.push_config
  for all to anon, authenticated using (false) with check (false);

drop policy if exists push_outbox_no_client on public.push_outbox;
create policy push_outbox_no_client on public.push_outbox
  for all to anon, authenticated using (false) with check (false);
