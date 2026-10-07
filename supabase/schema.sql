-- Kör i Supabase: SQL Editor → New query → klistra in → Run.
-- En tabell för alla dagliga spel; kolumnen "game" skiljer dem åt.

create table if not exists public.results (
  id         bigint generated always as identity primary key,
  game       text        not null,
  day        int         not null,
  player_id  uuid        not null,
  attempts   int         not null,
  won        boolean     not null,
  created_at timestamptz not null default now(),
  unique (game, day, player_id)
);

alter table public.results enable row level security;

-- Anonyma spelare får bara lägga till rimliga resultat, aldrig läsa eller ändra rader.
drop policy if exists "insert results" on public.results;
create policy "insert results" on public.results
  for insert to anon, authenticated
  with check (
    game in ('hexle')
    and day between 1 and 100000
    and attempts between 1 and 6
  );

-- Statistik för en dag: antal spelare och fördelning av antal försök.
-- security definer gör att funktionen kan läsa tabellen trots att klienter inte kan det.
create or replace function public.day_stats(p_game text, p_day int)
returns json
language sql
stable
security definer
set search_path = public
as $$
  select json_build_object(
    'players', (select count(*) from public.results
                where game = p_game and day = p_day),
    'wins',    (select count(*) from public.results
                where game = p_game and day = p_day and won),
    'dist',    coalesce((select json_object_agg(attempts, n)
                         from (select attempts, count(*) as n
                               from public.results
                               where game = p_game and day = p_day and won
                               group by attempts) d),
                        '{}'::json)
  );
$$;

revoke all on function public.day_stats(text, int) from public;
grant execute on function public.day_stats(text, int) to anon, authenticated;
