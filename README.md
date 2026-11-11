# Account Statistics

A World of Warcraft: Forever add-on that shows the in-game Statistics of all your characters side by side, plus totals across your whole account. Search for a Statistic, for example "death", and see every character's value and the account total on one row.

> **Status:** early development. Each character saves a Snapshot of its Statistics. `/stats` or the Minimap button opens the Statistics window: every Statistic with the chosen character's value and the Account Total. Drag the Minimap button to move it around the Minimap; `/stats minimap` hides it, and shows it again. `/stats list` lists the Tracked Characters with when each last synced, and `/stats dump <Statistic ID>` shows one Statistic for each with its Account Total. See the [issues](../../issues) for the roadmap.

## How it works

WoW only lets an add-on read the Statistics of the character you are logged in with. So each character saves a Snapshot of its Statistics when you log in, log out, or `/reload`, and the add-on combines those Snapshots. A character shows up after you have logged in with it once while the add-on is enabled. To Forget one, for example after deleting it, hover it in the window's character dropdown and click its X; logging it in again tracks it anew. See [docs/adr/0001-snapshots-only.md](docs/adr/0001-snapshots-only.md) for why.

Terms such as Snapshot, Tracked Character and Account Total are defined in [GLOSSARY.md](GLOSSARY.md).

## Install

Copy the `AccountStatistics` folder into `World of Warcraft/_forever_/Interface/AddOns/` and restart the game.

## Development

Requires Python 3, a C compiler, `make`, `unzip` and `rsync` (WSL or Linux).

```sh
scripts/setup-dev.sh   # once: installs Lua 5.1, LuaRocks, busted and luacheck into .lua/
scripts/check.sh       # lint and run the unit tests
scripts/deploy.sh      # copy the add-on into the Forever AddOns folder
```

After deploying, type `/reload` in game. New files and `.toc` changes need a full client restart. If your game is not in the default location, set `WOW_FOREVER_DIR` to your `_forever_` folder.
