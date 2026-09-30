#!/bin/sh
set -eu

repo_dir=$(cd -- "$(dirname -- "$0")/../.." && pwd)

unset MODEL PORT OLLAMA_HOST TIER QUANT CTX KEEP_ALIVE NUM_PARALLEL \
  AGENT_MODEL AGENT_API_KEY AGENT_BASE_URL OPENCODE_BINARY PI_BINARY CODEX_BINARY \
  OPENCODE_CONFIG_PATH PI_CONFIG_PATH CODEX_CONFIG_PATH
# shellcheck disable=SC1091
. "$repo_dir/config.sh"
[ "$MODEL" = devstral ]
[ "$PORT" = 11434 ]
[ "$OLLAMA_HOST" = 0.0.0.0:11434 ]
[ "$(sh -c 'printf %s "$OLLAMA_HOST"')" = 0.0.0.0:11434 ]
[ "$TIER" = 32 ]
[ "$QUANT" = q5_K_M ]
[ "$CTX" = 8192 ]
[ "$KEEP_ALIVE" = -1 ]
[ "$NUM_PARALLEL" = 2 ]
[ "$AGENT_MODEL" = devstral ]
[ "$AGENT_API_KEY" = ollama ]
[ "$AGENT_BASE_URL" = http://127.0.0.1:11434/v1 ]
[ "$OPENCODE_BINARY" = opencode ]
[ "$PI_BINARY" = pi ]
[ "$CODEX_BINARY" = codex ]
[ "$OPENCODE_CONFIG_PATH" = "$HOME/.config/opencode/opencode.json" ]
[ "$PI_CONFIG_PATH" = "$HOME/.pi/agent/models.json" ]
[ "$CODEX_CONFIG_PATH" = "$HOME/.codex/config.toml" ]
[ "$OPENCODE_CONFIG" = "$OPENCODE_CONFIG_PATH" ]
[ "$PI_CONFIG" = "$PI_CONFIG_PATH" ]
[ "$CODEX_CONFIG" = "$CODEX_CONFIG_PATH" ]

TIER=16 QUANT='' CTX='' MODEL='' PORT='' KEEP_ALIVE='' NUM_PARALLEL='' \
  sh -c '. "$1"; [ "$QUANT" = q4_K_M ]; [ "$CTX" = 4096 ]; [ "$NUM_PARALLEL" = 1 ]' sh "$repo_dir/config.sh"

for expected in \
  '16 q4_K_M 4096 1' \
  '24 q4_K_M 8192 1' \
  '32 q5_K_M 8192 2' \
  '48 q6_K 16384 2' \
  '64 q8_0 32768 4' \
  '96 q8_0 32768 6' \
  '128 q8_0 65536 8'; do
  IFS=' ' read -r tier quant ctx num_parallel <<EOF
$expected
EOF
  TIER=$tier QUANT='' CTX='' NUM_PARALLEL='' \
    sh -c '. "$1"; [ "$TIER" = "$2" ]; [ "$QUANT" = "$3" ]; [ "$CTX" = "$4" ]; [ "$NUM_PARALLEL" = "$5" ]' \
    sh "$repo_dir/config.sh" "$tier" "$quant" "$ctx" "$num_parallel"
done

MODEL=custom PORT=12345 OLLAMA_HOST='' TIER=64 QUANT=q4_0 CTX=2048 KEEP_ALIVE=30 NUM_PARALLEL=4 \
  sh -c '. "$1"; [ "$MODEL" = custom ]; [ "$PORT" = 12345 ]; [ "$OLLAMA_HOST" = 0.0.0.0:12345 ]; [ "$TIER" = 64 ]; [ "$QUANT" = q4_0 ]; [ "$CTX" = 2048 ]; [ "$KEEP_ALIVE" = 30 ]; [ "$NUM_PARALLEL" = 4 ]; [ "$(sh -c '\''printf %s "$OLLAMA_HOST"'\'')" = 0.0.0.0:12345 ]' sh "$repo_dir/config.sh"

HOME=/tmp/agent-home AGENT_MODEL=custom AGENT_API_KEY=test-key \
  AGENT_BASE_URL=http://dev-mac.local:11434/v1 OPENCODE_BINARY=custom-opencode \
  PI_BINARY=custom-pi CODEX_BINARY=custom-codex \
  OPENCODE_CONFIG_PATH=/tmp/opencode.json PI_CONFIG_PATH=/tmp/pi.json \
  CODEX_CONFIG_PATH=/tmp/codex.toml \
  sh -c '. "$1"; [ "$AGENT_MODEL" = custom ]; [ "$AGENT_API_KEY" = test-key ]; [ "$AGENT_BASE_URL" = http://dev-mac.local:11434/v1 ]; [ "$OPENCODE_BINARY" = custom-opencode ]; [ "$PI_BINARY" = custom-pi ]; [ "$CODEX_BINARY" = custom-codex ]; [ "$OPENCODE_CONFIG_PATH" = /tmp/opencode.json ]; [ "$PI_CONFIG_PATH" = /tmp/pi.json ]; [ "$CODEX_CONFIG_PATH" = /tmp/codex.toml ]' sh "$repo_dir/config.sh"
echo "config.sh tests passed"
