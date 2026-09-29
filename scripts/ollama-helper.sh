#!/bin/sh
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$script_dir/../config.sh"
OLLAMA_API_URL=${OLLAMA_API_URL:-http://$OLLAMA_HOST}
export OLLAMA_HOST
ollama_curl() { endpoint=$1; shift; curl -fsS "$@" "$OLLAMA_API_URL$endpoint"; }
json_escape() { printf '%s' "$1" | sed 's/[\\]/\\\\/g; s/"/\\"/g; :a;N;$!ba;s/\n/\\n/g'; }
json_field() { key=$1; sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"\\]*\)".*/\1/p' | head -n 1; }
json_number() { key=$1; sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n 1; }
