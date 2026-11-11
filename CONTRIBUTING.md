# Contributing

Terms such as Snapshot, Tracked Character and Account Total are defined in [GLOSSARY.md](GLOSSARY.md); design decisions are in [docs/adr/](docs/adr/).

## Development

Requires Python 3, a C compiler, `make`, `unzip` and `rsync` (WSL or Linux).

```sh
scripts/setup-dev.sh   # once: installs Lua 5.1, LuaRocks, busted and luacheck into .lua/
scripts/check.sh       # lint and run the unit tests
scripts/deploy.sh      # copy the add-on into the Forever AddOns folder
```

After deploying, type `/reload` in game. New files and `.toc` changes need a full client restart. If your game is not in the default location, set `WOW_FOREVER_DIR` to your `_forever_` folder.

`/stats list` lists the Tracked Characters with when each last synced, and `/stats dump <Statistic ID>` shows one Statistic for each with its Account Total.

## Releasing

1. Add a section for the new version at the top of [CHANGELOG.md](CHANGELOG.md) and merge it into `main`.
2. On GitHub, draft a new release on `main` with a new tag such as `1.2.0` ([SemVer](https://semver.org), no `v`), and publish it.

The [Release workflow](.github/workflows/release.yml) then runs the checks, stamps the tag into the `.toc` as the version, attaches the zip to the GitHub Release and uploads it to CurseForge. A tag containing `alpha` or `beta` becomes an alpha or beta file on CurseForge.
