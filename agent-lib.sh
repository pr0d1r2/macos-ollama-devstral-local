#!/bin/sh

# Shared implementation for the agent gateways. This file is sourced by the
# thin wrappers, so do not enable `set -e` or consume positional parameters.

agent_script_dir=$(CDPATH='' cd -- "$(dirname -- "${0:-agent-lib.sh}")" && pwd)
# shellcheck disable=SC1091
. "$agent_script_dir/config.sh"

eval "$(cat <<'agent_lib_functions'
agent_path_without_script_dir() {
  old_ifs=$IFS
  IFS=:
  result=
  for path_entry in ${PATH-}; do
    [ -n "$path_entry" ] || continue
    path_entry=$(CDPATH='' cd -- "$path_entry" 2>/dev/null && pwd) || continue
    [ "$path_entry" = "$agent_script_dir" ] && continue
    if [ -n "$result" ]; then result=$result:$path_entry; else result=$path_entry; fi
  done
  IFS=$old_ifs
  printf '%s\n' "$result"
}

agent_resolve_binary() {
  agent_binary=$1
  agent_path=$(agent_path_without_script_dir)
  if [ -n "$agent_path" ] && resolved_binary=$(PATH=$agent_path command -v "$agent_binary") &&
    [ -x "$resolved_binary" ]; then
    printf '%s\n' "$resolved_binary"
    return 0
  fi
  echo "Agent binary not found: $agent_binary. Install it or add it to PATH." >&2
  return 1
}

agent_verify_model() {
  models_url=${AGENT_BASE_URL%/}/models
  models_response=$(curl -fsS "$models_url") || {
    echo "Could not query Ollama models at $models_url." >&2
    return 1
  }
  model_ids=$(printf '%s\n' "$models_response" |
    sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"\\]*\)".*/\1/p')
  for model_id in $model_ids; do
    [ "$model_id" = "$AGENT_MODEL" ] || [ "$model_id" = "$AGENT_MODEL:latest" ] && return 0
  done
  echo "Ollama model tag not found at $models_url: $AGENT_MODEL (or ${AGENT_MODEL}:latest)." >&2
  return 1
}

agent_exec() {
  agent_binary=$1
  shift
  agent_real_binary=$(agent_resolve_binary "$agent_binary") || return 1
  agent_verify_model || return 1
  exec "$agent_real_binary" "$@"
}
agent_lib_functions
)"
