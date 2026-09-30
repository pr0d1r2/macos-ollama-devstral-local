#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$script_dir/agent-lib.sh"

config_dir=$(dirname -- "$OPENCODE_CONFIG_PATH")
mkdir -p "$config_dir"
cat >"$OPENCODE_CONFIG_PATH" <<EOF
{
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "$AGENT_BASE_URL",
        "apiKey": "$AGENT_API_KEY"
      },
      "models": {
        "$AGENT_MODEL": {}
      }
    }
  },
  "model": "ollama/$AGENT_MODEL"
}
EOF

agent_exec "$OPENCODE_BINARY" "$@"
