#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$script_dir/agent-lib.sh"

config_dir=$(dirname -- "$CODEX_CONFIG_PATH")
mkdir -p "$config_dir"
cat >"$CODEX_CONFIG_PATH" <<EOF
model = "$AGENT_MODEL"
model_provider = "ollama-local"

[model_providers.ollama-local]
base_url = "$AGENT_BASE_URL"
wire_api = "responses"
EOF

agent_exec "$CODEX_BINARY" "$@"
