#!/bin/sh
set -eu
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
if [ "$#" -gt 0 ]; then prompt=$*; else prompt=$(cat); fi
escaped_model=$("$script_dir/ollama-helper.sh" escape "$MODEL")
escaped_prompt=$("$script_dir/ollama-helper.sh" escape "$prompt")
payload='{"model":"'"$escaped_model"'","prompt":"'"$escaped_prompt"'","stream":false}'
response=$("$script_dir/ollama-helper.sh" curl /api/generate -H 'Content-Type: application/json' -d "$payload")
printf '%s\n' "$response" | "$script_dir/ollama-helper.sh" field response
printf 'total_duration=%s\neval_count=%s\n' "$(printf '%s' "$response" | "$script_dir/ollama-helper.sh" number total_duration)" "$(printf '%s' "$response" | "$script_dir/ollama-helper.sh" number eval_count)" >&2
