#!/bin/sh
# Shared runtime configuration.  Keep this file POSIX sh so every runtime
# script can source it on a clean macOS installation.

# Users may override the scalar settings in the environment.  TIER selects the
# RAM-safe quantization/context defaults below; QUANT and CTX can fine-tune a
# selected tier without changing the tier label.
MODEL=${MODEL:-devstral}
PORT=${PORT:-11434}
OLLAMA_HOST=${OLLAMA_HOST:-0.0.0.0:$PORT}
TIER=${TIER:-32}
KEEP_ALIVE=${KEEP_ALIVE:--1}

case $TIER in
  16)
    # 16 GB is the minimum and marginal for Devstral 24B: use the smallest
    # quant/context/concurrency combination to reduce OOM pressure.
    DEFAULT_QUANT=q4_K_M
    DEFAULT_CTX=4096
    DEFAULT_NUM_PARALLEL=1
    ;;
  24)
    DEFAULT_QUANT=q4_K_M
    DEFAULT_CTX=8192
    DEFAULT_NUM_PARALLEL=1
    ;;
  32)
    DEFAULT_QUANT=q5_K_M
    DEFAULT_CTX=8192
    DEFAULT_NUM_PARALLEL=2
    ;;
  48)
    DEFAULT_QUANT=q6_K
    DEFAULT_CTX=16384
    DEFAULT_NUM_PARALLEL=2
    ;;
  64)
    DEFAULT_QUANT=q8_0
    DEFAULT_CTX=32768
    DEFAULT_NUM_PARALLEL=4
    ;;
  96)
    DEFAULT_QUANT=q8_0
    DEFAULT_CTX=32768
    DEFAULT_NUM_PARALLEL=6
    ;;
  128)
    DEFAULT_QUANT=q8_0
    DEFAULT_CTX=65536
    DEFAULT_NUM_PARALLEL=8
    ;;
  *)
    echo "Unsupported RAM tier: $TIER (expected 16, 24, 32, 48, 64, 96, or 128)" >&2
    exit 1
    ;;
esac

QUANT=${QUANT:-$DEFAULT_QUANT}
CTX=${CTX:-$DEFAULT_CTX}
NUM_PARALLEL=${NUM_PARALLEL:-$DEFAULT_NUM_PARALLEL}

# Agent gateways use Ollama's OpenAI-compatible API.  Keep these settings in
# the shared config so each wrapper has one consistent, overridable contract.
AGENT_MODEL=${AGENT_MODEL:-$MODEL}
AGENT_API_KEY=${AGENT_API_KEY:-ollama}
AGENT_BASE_URL=${AGENT_BASE_URL:-http://127.0.0.1:$PORT/v1}

OPENCODE_BINARY=${OPENCODE_BINARY:-opencode}
PI_BINARY=${PI_BINARY:-pi}
CODEX_BINARY=${CODEX_BINARY:-codex}

OPENCODE_CONFIG_PATH=${OPENCODE_CONFIG_PATH:-${HOME:?}/.config/opencode/opencode.json}
PI_CONFIG_PATH=${PI_CONFIG_PATH:-${HOME:?}/.pi/agent/models.json}
CODEX_CONFIG_PATH=${CODEX_CONFIG_PATH:-${HOME:?}/.codex/config.toml}

# Short aliases are useful to wrappers and preserve a compact shell-facing
# interface while the *_PATH names document that these are file destinations.
export OPENCODE_CONFIG="$OPENCODE_CONFIG_PATH"
export PI_CONFIG="$PI_CONFIG_PATH"
export CODEX_CONFIG="$CODEX_CONFIG_PATH"

# All script-owned Ollama CLI/API calls must target the managed service rather
# than a separate localhost-default Ollama instance.
export OLLAMA_HOST
