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
