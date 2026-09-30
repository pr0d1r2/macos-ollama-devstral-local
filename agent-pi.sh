#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$script_dir/agent-lib.sh"

config_dir=$(dirname -- "$PI_CONFIG_PATH")
mkdir -p "$config_dir"
cat >"$PI_CONFIG_PATH" <<EOF
{
  "providers": {
    "ollama": {
      "baseUrl": "$AGENT_BASE_URL",
      "api": "openai-completions",
      "apiKey": "$AGENT_API_KEY",
      "models": [
        {"id": "$AGENT_MODEL"}
      ]
    }
  }
}
EOF

agent_exec "$PI_BINARY" "$@"
