-- Kör i Supabase: SQL Editor → New query → klistra in → Run.
-- Filen går att köra flera gånger; den uppdaterar en befintlig databas.
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

-- Topplista: tid till vinst, valfritt namn och antal ledtrådar.
alter table public.results add column if not exists time_ms int;
alter table public.results add column if not exists name    text;
alter table public.results add column if not exists hints   int not null default 0;

alter table public.results enable row level security;

-- Uttryckliga rättigheter, så att det fungerar även när "Automatically expose
-- new tables" är avstängt. Bara insert; läsning sker via day_stats() nedan.
revoke all on public.results from anon, authenticated;
grant insert on public.results to anon, authenticated;

-- Anonyma spelare får bara lägga till rimliga resultat, aldrig läsa eller ändra rader.
drop policy if exists "insert results" on public.results;
create policy "insert results" on public.results
  for insert to anon, authenticated
  with check (
    game in ('hexle')
    and day between 1 and 100000
    and attempts between 1 and 6
    and hints between 0 and 3
    and (time_ms is null or time_ms between 1000 and 86400000)
    and (name is null or char_length(btrim(name)) between 1 and 16)
  );

-- Statistik för en dag: antal spelare, fördelning, dagens snabbaste och egen placering.
-- security definer gör att funktionen kan läsa tabellen trots att klienter inte kan det.
drop function if exists public.day_stats(text, int);
create or replace function public.day_stats(p_game text, p_day int, p_player uuid default null)
returns json
language sql
stable
security definer
set search_path = public
as $$
  with today as (
    select * from public.results where game = p_game and day = p_day
  ),
  ranked as (
    select player_id, name, attempts, time_ms, hints,
           row_number() over (order by time_ms, created_at) as pos
    from today
    where won and time_ms is not null
  )
  select json_build_object(
    'players', (select count(*) from today),
    'wins',    (select count(*) from today where won),
    'dist',    coalesce((select json_object_agg(attempts, n)
                         from (select attempts, count(*) as n from today
                               where won group by attempts) d),
                        '{}'::json),
    'fastest', coalesce((select json_agg(json_build_object(
                           'pos', pos, 'name', coalesce(name, 'Anonym'), 'attempts', attempts,
                           'time_ms', time_ms, 'hints', hints, 'me', player_id = p_player)
                         order by pos)
                         from ranked where pos <= 10),
                        '[]'::json),
    'my_pos',  (select pos from ranked where player_id = p_player),
    'ranked',  (select count(*) from ranked)
  );
$$;

revoke all on function public.day_stats(text, int, uuid) from public;
grant execute on function public.day_stats(text, int, uuid) to anon, authenticated;
