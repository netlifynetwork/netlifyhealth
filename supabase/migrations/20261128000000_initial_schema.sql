-- Netlify Health initial schema. Every personal row is scoped to auth.uid().
create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  birth_date date not null,
  height_cm numeric(5,2) not null check (height_cm between 80 and 250),
  current_weight_kg numeric(5,2) not null check (current_weight_kg between 20 and 400),
  goal text not null check (goal in ('Lose weight','Maintain weight','Gain weight','Improve fitness')),
  activity_level text not null check (activity_level in ('Sedentary','Light','Moderate','Active','Very active')),
  dietary_preference text not null,
  allergies text not null default 'None',
  calorie_goal integer not null check (calorie_goal between 800 and 6000),
  water_goal_ml integer not null default 2000 check (water_goal_ml between 250 and 10000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.meal_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_on date not null default current_date,
  meal_type text not null check (meal_type in ('Breakfast','Morning snack','Lunch','Afternoon snack','Dinner','Evening snack')),
  food_name text not null,
  serving text not null,
  calories integer not null check (calories >= 0),
  protein_g numeric(8,2) not null default 0 check (protein_g >= 0),
  carbs_g numeric(8,2) not null default 0 check (carbs_g >= 0),
  fat_g numeric(8,2) not null default 0 check (fat_g >= 0),
  completed boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.water_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_on date not null default current_date,
  amount_ml integer not null check (amount_ml between 1 and 5000),
  created_at timestamptz not null default now()
);

create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_on date not null default current_date,
  activity_name text not null,
  duration_minutes integer not null check (duration_minutes between 1 and 1440),
  steps integer not null default 0 check (steps >= 0),
  calories_burned integer not null default 0 check (calories_burned >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.weight_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  measured_on date not null default current_date,
  weight_kg numeric(5,2) not null check (weight_kg between 20 and 400),
  note text,
  created_at timestamptz not null default now(),
  unique(user_id, measured_on)
);

create table if not exists public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  theme text not null default 'system' check (theme in ('system','light','dark')),
  meal_reminders boolean not null default true,
  water_reminders boolean not null default true,
  activity_reminders boolean not null default true,
  goal_reminders boolean not null default true,
  updated_at timestamptz not null default now()
);

do $$
declare t text;
begin
  foreach t in array array['profiles','meal_logs','water_logs','activity_logs','weight_entries','user_settings']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "Users manage own %I" on public.%I', t, t);
    execute format('create policy "Users manage own %I" on public.%I for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()))', t, t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists settings_updated_at on public.user_settings;
create trigger settings_updated_at before update on public.user_settings
for each row execute function public.set_updated_at();

grant usage on schema public to authenticated;
