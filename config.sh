#!/bin/sh
# Shared runtime configuration.  Keep this file POSIX sh so every runtime
# script can source it on a clean macOS installation.

# Users may override the scalar settings in the environment.  TIER selects the
# RAM-safe quantization/context defaults below; QUANT and CTX can fine-tune a
# selected tier without changing the tier label.
MODEL=${MODEL:-devstral}
PORT=${PORT:-11434}
TIER=${TIER:-32}
KEEP_ALIVE=${KEEP_ALIVE:--1}
NUM_PARALLEL=${NUM_PARALLEL:-2}

case $TIER in
  16)
    DEFAULT_QUANT=q4_K_M
    DEFAULT_CTX=4096
    ;;
  24)
    DEFAULT_QUANT=q4_K_M
    DEFAULT_CTX=8192
    ;;
  32)
    DEFAULT_QUANT=q5_K_M
    DEFAULT_CTX=8192
    ;;
  48)
    DEFAULT_QUANT=q6_K
    DEFAULT_CTX=16384
    ;;
  64)
    DEFAULT_QUANT=q8_0
    DEFAULT_CTX=32768
    ;;
  96)
    DEFAULT_QUANT=q8_0
    DEFAULT_CTX=32768
    ;;
  128)
    DEFAULT_QUANT=q8_0
    DEFAULT_CTX=65536
    ;;
  *)
    echo "Unsupported RAM tier: $TIER (expected 16, 24, 32, 48, 64, 96, or 128)" >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

QUANT=${QUANT:-$DEFAULT_QUANT}
CTX=${CTX:-$DEFAULT_CTX}

