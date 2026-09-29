#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$script_dir/config.sh"

architecture=$(uname -m)
if [ "$architecture" != arm64 ]; then
  echo "Unsupported architecture: $architecture (this script requires arm64)." >&2
  exit 1
fi

# Ollama.app is the supported installer on macOS.  Prefer the CLI shipped in
# the bundle so a stale PATH installation cannot accidentally control the
# service; retain a PATH fallback for developer setups and older installs.
OLLAMA_APP=${OLLAMA_APP:-/Applications/Ollama.app}
OLLAMA_CLI=

if [ ! -d "$OLLAMA_APP" ]; then
  download_url=https://ollama.com/download
  poll_interval=${OLLAMA_INSTALL_POLL_INTERVAL:-5}

  echo "Ollama.app is not installed. Opening $download_url."
  echo "Install Ollama for macOS, move Ollama.app to $OLLAMA_APP, and finish any prompts."
  echo "Waiting for Ollama.app to be installed..."
  open "$download_url"

  while [ ! -d "$OLLAMA_APP" ]; do
    sleep "$poll_interval"
  done
  echo "Ollama.app detected. Continuing setup."
fi

if [ -x "$OLLAMA_APP/Contents/Resources/ollama" ]; then
  OLLAMA_CLI=$OLLAMA_APP/Contents/Resources/ollama
elif command -v ollama >/dev/null 2>&1; then
  OLLAMA_CLI=$(command -v ollama)
fi

if [ -z "$OLLAMA_CLI" ]; then
  echo "Ollama CLI not found. Install /Applications/Ollama.app or add ollama to PATH." >&2
  exit 1
fi

# Ollama.app may be registered as a macOS login item and start its menubar
# process (and potentially its own server) at login.  Removing the login item
# is best-effort: System Events may require Automation permission, and some
# app versions do not expose the item under this name.
if command -v osascript >/dev/null 2>&1 &&
  osascript -e 'tell application "System Events" to delete login item "Ollama"' >/dev/null 2>&1; then
  echo "Disabled Ollama.app menubar login item."
else
  echo "Could not automatically disable Ollama.app menubar autostart."
  echo "Manual fallback: System Settings → General → Login Items → remove or disable Ollama."
fi
export OLLAMA_CLI

plist_path=$(HOME=${HOME:?} OLLAMA_CLI="$OLLAMA_CLI" \
  sh "$script_dir/scripts/gen-plist.sh")

# Reload the managed LaunchAgent so rerunning start.sh replaces the existing
# service cleanly instead of creating a competing instance.
launchctl unload "$plist_path" >/dev/null 2>&1 || true
launchctl load "$plist_path"
echo "Loaded Ollama LaunchAgent: $plist_path"

# Pull the configured model only when it is not already installed.  The
# trailing :latest tag is Ollama's display convention, while MODEL remains
# the stable identifier used by the rest of the scripts.
if "$OLLAMA_CLI" list 2>/dev/null |
  awk -v model="$MODEL" '$1 == model || $1 == model ":latest" { found = 1 } END { exit !found }'; then
  echo "Model already present: $MODEL"
else
  echo "Pulling model: $MODEL"
  "$OLLAMA_CLI" pull "$MODEL"
fi

# Prime the model after launchd has started the service.  An empty, non-streaming
# generate request loads the model into memory without producing user-visible
# output; retry while launchd finishes bringing the listener up.
echo "Warming model: $MODEL"
if ! curl -fsS --retry 30 --retry-delay 1 --retry-connrefused \
  -H 'Content-Type: application/json' \
  -d '{"model":"'"$MODEL"'","prompt":"","stream":false,"keep_alive":'"$KEEP_ALIVE"'}' \
  "http://127.0.0.1:$PORT/api/generate" >/dev/null; then
  echo "Failed to warm model through Ollama at http://127.0.0.1:$PORT." >&2
  exit 1
fi
echo "Model warm: $MODEL"
