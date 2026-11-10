# Forever Account Stats

WoW: Forever add-on: every Character's Statistics side by side, plus Account Totals. Speak the language of [GLOSSARY.md](GLOSSARY.md) in code, issues and commits; when a new domain term settles, add it there. Design decisions with real trade-offs go in [docs/adr/](docs/adr/).

## WoW: Forever facts

- Forever runs the **retail (Midnight) client and API** on interface `16001`, with vanilla-era content. Look up APIs in retail docs ([warcraft.wiki.gg](https://warcraft.wiki.gg)), not Classic ones.
- Read Blizzard's interface code (FrameXML, templates, atlas names) only from files exported from the user's own Forever client, never from third-party mirrors of it. The user exports them by launching with `-console` and typing `ExportInterfaceFiles code` in the console (`` ` ``) on the login or character select screen; in the world it reads "Unknown console command". When `` ` `` opens nothing (e.g. on a non-US keyboard), first type `/run SetConsoleKey("#")` in the world, then log out to character select and press `#`; the key lasts until the game quits. They land in `_forever_/BlizzardInterfaceCode/`.
- `select(4, GetBuildInfo())` is `16001`, so retail-style checks like `>= 100000` take the wrong branch.
- The game runs **Lua 5.1**; the local toolchain matches it. Write 5.1: no `//`, bitwise operators, `goto`, `utf8` or `math.type`.
- `UnitName("player")` returns first name and **surname**. The surname is not a realm.
- SavedVariables reach disk only on logout, `/reload` or quit; `PLAYER_LOGOUT` is the last chance to write.
- `GetStatistic` returns display strings (`"250"`, `"--"`, coin-texture strings for gold), never numbers.
- Midnight's "secret values" restrict combat data; Statistics are unaffected.

## Code layout

Game API calls live in thin adapter files. Everything else (parsing values, Account Totals, search filtering) is pure Lua that takes plain data as arguments and is covered by busted specs in `spec/`. User-facing text lives only in `Locale.lua`.

## Workflow

1. `scripts/setup-dev.sh` once per clone.
2. `scripts/check.sh` before every commit; CI runs the same.
3. `scripts/deploy.sh`, then the user verifies in game: hand them the exact steps (`/reload` or client restart, what to type, what they should see) and wait for their report.

## Code reference

Reuse code only from permissively licensed sources, with attribution. Baganator, Syndicator and Accountwide Stats (GPLv2) are off-limits as code reference; learn from their user-visible behaviour only.
