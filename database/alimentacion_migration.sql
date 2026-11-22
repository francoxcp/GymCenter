-- =============================================================================
-- GYMLAB · Alimentación: datos del cuestionario del socio
-- Idempotente. Ejecutar en Supabase → SQL Editor.
--
--  activity_level : actividad fuera del gym (sedentary | standing | physical)
--  food_avoid     : lo que no come (dairy, egg, seafood, red_meat, pork)
--  meals_per_day  : comidas al día (3 a 5)
--
-- RLS: las políticas actuales de public.users ya permiten que cada usuario
-- edite su fila y que su entrenador/dueño la lea. users_guard no toca estas
-- columnas.
-- =============================================================================

begin;

alter table public.users add column if not exists activity_level text;
alter table public.users add column if not exists food_avoid text[] not null default '{}';
alter table public.users add column if not exists meals_per_day smallint;

alter table public.users drop constraint if exists users_activity_level_check;
alter table public.users
  add constraint users_activity_level_check
  check (activity_level is null or activity_level in ('sedentary', 'standing', 'physical'));

alter table public.users drop constraint if exists users_food_avoid_check;
alter table public.users
  add constraint users_food_avoid_check
  check (food_avoid <@ array['dairy', 'egg', 'seafood', 'red_meat', 'pork']::text[]);

alter table public.users drop constraint if exists users_meals_per_day_check;
alter table public.users
  add constraint users_meals_per_day_check
  check (meals_per_day is null or meals_per_day between 3 and 5);

commit;
