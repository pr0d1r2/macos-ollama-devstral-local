#!/bin/sh
set -eu
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$script_dir/ollama-helper.sh"
model=${1:-$MODEL}
ollama_curl /api/show -H 'Content-Type: application/json' -d '{"name":"'$(json_escape "$model")'"}'
