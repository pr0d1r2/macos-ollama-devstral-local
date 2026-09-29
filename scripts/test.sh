#!/bin/sh
set -eu
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$script_dir/ollama-helper.sh"
payload='{"model":"'$(json_escape "$MODEL")'","prompt":"'$(json_escape "${1:-Reply with OK.}")'","stream":false}'
response=$(ollama_curl /api/generate -H 'Content-Type: application/json' -d "$payload")
printf '%s\n' "$response"
printf 'total_duration=%s\neval_count=%s\n' "$(printf '%s' "$response" | json_number total_duration)" "$(printf '%s' "$response" | json_number eval_count)" >&2
