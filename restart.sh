#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$script_dir/config.sh"

launch_agents_dir=${LAUNCH_AGENTS_DIR:-${HOME:?}/Library/LaunchAgents}
label=${OLLAMA_LAUNCHD_LABEL:-com.pr0d1r2.ollama-devstral-local}
plist_path=${OLLAMA_PLIST_PATH:-$launch_agents_dir/$label.plist}

# Unloading an absent job is already the desired first half of a restart.
launchctl unload "$plist_path" >/dev/null 2>&1 || true
launchctl load "$plist_path"
echo "Restarted Ollama LaunchAgent: $plist_path"
