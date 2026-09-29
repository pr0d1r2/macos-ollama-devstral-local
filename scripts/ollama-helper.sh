#!/bin/sh
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$script_dir/../config.sh"
OLLAMA_API_URL=${OLLAMA_API_URL:-http://$OLLAMA_HOST}
export OLLAMA_HOST
case ${1:-} in
  curl)
    endpoint=$2
    shift 2
    curl -fsS "$@" "$OLLAMA_API_URL$endpoint"
    ;;
  escape)
    printf '%s' "$2" | sed 's/[\\]/\\\\/g; s/"/\\"/g; :a;N;$!ba;s/\n/\\n/g'
    ;;
  field)
    key=$2
    sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"\\]*\)".*/\1/p' | head -n 1
    ;;
  number)
    key=$2
    sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n 1
    ;;
esac
