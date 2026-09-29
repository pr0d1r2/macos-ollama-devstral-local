#!/bin/sh
set -eu

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

export OLLAMA_CLI
