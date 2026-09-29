#!/bin/sh
set -eu
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
model=${1:-$MODEL}
escaped_model=$("$script_dir/ollama-helper.sh" escape "$model")
"$script_dir/ollama-helper.sh" curl /api/show -H 'Content-Type: application/json' -d '{"name":"'"$escaped_model"'"}'
