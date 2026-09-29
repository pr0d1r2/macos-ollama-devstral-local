#!/bin/sh
set -eu

repo_dir=$(cd -- "$(dirname -- "$0")/../.." && pwd)

unset MODEL PORT OLLAMA_HOST TIER QUANT CTX KEEP_ALIVE NUM_PARALLEL
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

TIER=16 QUANT='' CTX='' MODEL='' PORT='' KEEP_ALIVE='' NUM_PARALLEL='' \
  sh -c '. "$1"; [ "$QUANT" = q4_K_M ]; [ "$CTX" = 4096 ]' sh "$repo_dir/config.sh"

MODEL=custom PORT=12345 OLLAMA_HOST='' TIER=64 QUANT=q4_0 CTX=2048 KEEP_ALIVE=30 NUM_PARALLEL=4 \
  sh -c '. "$1"; [ "$MODEL" = custom ]; [ "$PORT" = 12345 ]; [ "$OLLAMA_HOST" = 0.0.0.0:12345 ]; [ "$TIER" = 64 ]; [ "$QUANT" = q4_0 ]; [ "$CTX" = 2048 ]; [ "$KEEP_ALIVE" = 30 ]; [ "$NUM_PARALLEL" = 4 ]; [ "$(sh -c '\''printf %s "$OLLAMA_HOST"'\'')" = 0.0.0.0:12345 ]' sh "$repo_dir/config.sh"
echo "config.sh tests passed"
