#!/usr/bin/env bash
# Copies the add-on into the WoW: Forever AddOns folder, with the version stamped from git (e.g. 1.0.0-3-gabc1234).
# Afterwards: /reload in game for Lua edits; restart the client for new files or .toc changes.
set -euo pipefail
cd "$(dirname "$0")/.."

wow_dir="${WOW_FOREVER_DIR:-/mnt/c/Program Files (x86)/World of Warcraft/_forever_}"
addons_dir="$wow_dir/Interface/AddOns"

if [ ! -d "$addons_dir" ]; then
  echo "AddOns folder not found: $addons_dir (set WOW_FOREVER_DIR to your _forever_ folder)" >&2
  exit 1
fi

version=$(git describe --tags --always --dirty)
rsync -a --delete AccountStatistics/ "$addons_dir/AccountStatistics/"
sed -i "s/@project-version@/$version/" "$addons_dir/AccountStatistics/AccountStatistics.toc"
echo "Deployed $version to $addons_dir/AccountStatistics"
