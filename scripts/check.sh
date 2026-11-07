#!/usr/bin/env bash
# Lints and tests with the project-local Lua 5.1 toolchain (install it with scripts/setup-dev.sh).
set -euo pipefail
cd "$(dirname "$0")/.."
.lua/bin/luacheck .
.lua/bin/busted
