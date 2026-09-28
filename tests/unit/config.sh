#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

check_defaults() {
  unset MODEL PORT TIER QUANT CTX KEEP_ALIVE NUM_PARALLEL
  # shellcheck disable=SC1091
  . "$repo_dir/config.sh"
  [ "$MODEL" = devstral ]
  [ "$PORT" = 11434 ]
  [ "$TIER" = 32 ]
  [ "$QUANT" = q5_K_M ]
  [ "$CTX" = 8192 ]
  [ "$KEEP_ALIVE" = -1 ]
  [ "$NUM_PARALLEL" = 2 ]
}

check_tier() {
  TIER=16 QUANT= CTX= MODEL= PORT= KEEP_ALIVE= NUM_PARALLEL= \
    sh -c '. "$1"; [ "$QUANT" = q4_K_M ]; [ "$CTX" = 4096 ]' sh "$repo_dir/config.sh"
}

check_overrides() {
  MODEL=custom PORT=12345 TIER=64 QUANT=q4_0 CTX=2048 KEEP_ALIVE=30 NUM_PARALLEL=4 \
    sh -c '. "$1"; [ "$MODEL" = custom ]; [ "$PORT" = 12345 ]; [ "$TIER" = 64 ]; [ "$QUANT" = q4_0 ]; [ "$CTX" = 2048 ]; [ "$KEEP_ALIVE" = 30 ]; [ "$NUM_PARALLEL" = 4 ]' sh "$repo_dir/config.sh"
}

check_defaults
check_tier
check_overrides
echo "config.sh tests passed"
