# color-game

**Hexle**: ett dagligt färgspel. Alla får samma färg varje dag och ska gissa dess hexkod på 6 försök.

## Publicera med GitHub Pages

1. Repo → **Settings → Pages** → under *Build and deployment* välj **Source: GitHub Actions**.
2. Pusha (eller merga) till `main`. Workflowet `.github/workflows/pages.yml` publicerar automatiskt.
3. Spelet hamnar på `https://<användarnamn>.github.io/color-game/`.

## Statistik med Supabase (valfritt)

Spelet fungerar utan Supabase. Med Supabase visas hur många som spelat idag, fördelningen av antal försök och dagens snabbaste (topp 10).

`supabase/schema.sql` går att köra flera gånger. Kör den igen efter uppdateringar av spelet, **innan** du mergar, så att databasen har de nya kolumnerna.

1. Skapa ett projekt på [supabase.com](https://supabase.com) (eller använd ett befintligt; flera spel kan dela samma projekt).
2. **SQL Editor** → klistra in `supabase/schema.sql` → **Run**.
3. **Project Settings → API**: kopiera *Project URL* och *publishable/anon key* till `config.js`.
4. Pusha till `main`.

Nyckeln i `config.js` är gjord för att vara publik. Tabellen skyddas av Row Level Security:
besökare kan bara lägga till sitt eget resultat och läsa sammanställd statistik, aldrig enskilda rader.

> Gratisprojekt i Supabase pausas efter en veckas inaktivitet. Spelet fortsätter fungera, men statistiken visas inte förrän projektet är igång igen.
