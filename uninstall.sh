#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$script_dir/config.sh"

launch_agents_dir=${LAUNCH_AGENTS_DIR:-${HOME:?}/Library/LaunchAgents}
label=${OLLAMA_LAUNCHD_LABEL:-com.pr0d1r2.ollama-devstral-local}
plist_path=${OLLAMA_PLIST_PATH:-$launch_agents_dir/$label.plist}

# Stop before removing the job definition.  stop.sh deliberately tolerates an
# absent job, so uninstall is safe to run repeatedly.
sh "$script_dir/stop.sh"

rm -f "$plist_path"
echo "Removed Ollama LaunchAgent plist: $plist_path"

# These are script-local exports, but explicitly clear them so sourced use of
# this script cannot leave managed Ollama settings in its caller.
managed_host=$OLLAMA_HOST
unset OLLAMA_HOST OLLAMA_CLI

remove_model=${UNINSTALL_REMOVE_MODEL:-0}
case ${1:-} in
  '') ;;
  --remove-model) remove_model=1 ;;
  *)
    echo "Usage: $0 [--remove-model]" >&2
    exit 2
    ;;
esac

if [ "$remove_model" = 1 ]; then
  ollama_cli=${OLLAMA_CLI_PATH:-}
  if [ -z "$ollama_cli" ] && [ -x /Applications/Ollama.app/Contents/Resources/ollama ]; then
    ollama_cli=/Applications/Ollama.app/Contents/Resources/ollama
  fi
  if [ -z "$ollama_cli" ]; then
    ollama_cli=$(command -v ollama || true)
  fi
  if [ -z "$ollama_cli" ] || [ ! -x "$ollama_cli" ]; then
    echo "Ollama CLI not found; cannot remove model $MODEL." >&2
    exit 1
  fi
  OLLAMA_HOST=$managed_host "$ollama_cli" rm "$MODEL"
  echo "Removed Ollama model: $MODEL"
fi

echo "Ollama uninstall complete."
