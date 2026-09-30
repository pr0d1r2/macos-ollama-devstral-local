#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$script_dir/agent-lib.sh"

config_dir=$(dirname -- "$PI_CONFIG_PATH")
mkdir -p "$config_dir"
agent_render_template pi.models.json "$PI_CONFIG_PATH"

agent_exec "$PI_BINARY" "$@"
