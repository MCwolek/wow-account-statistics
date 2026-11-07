#!/usr/bin/env bash
# Installs a project-local Lua 5.1 toolchain (Lua, LuaRocks, busted, luacheck) into .lua/.
# WoW embeds Lua 5.1, so tests run on 5.1 too. No sudo needed; delete .lua/ and .venv/ to undo.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -x .venv/bin/hererocks ]; then
  python3 -m venv .venv
  .venv/bin/pip install --quiet hererocks
fi

if [ ! -x .lua/bin/luarocks ]; then
  .venv/bin/hererocks .lua --lua 5.1 --luarocks latest --no-readline
fi

.lua/bin/luarocks install busted
.lua/bin/luarocks install luacheck

echo "Done. Run scripts/check.sh to lint and test."
