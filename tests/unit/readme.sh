#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
readme=$repo_dir/README.md

grep -F 'Code → Download ZIP' "$readme" >/dev/null
grep -F 'sh start.sh' "$readme" >/dev/null
grep -F 'ZIP extraction can remove executable bits' "$readme" >/dev/null
grep -F 'waits for Ollama.app' "$readme" >/dev/null
grep -F 'TIER=64 sh start.sh' "$readme" >/dev/null

# T20: keep every supported RAM tier and its runtime tuning visible in the
# README, including the explicit warning for the minimum tier.
for row in \
  "| 16 GB | \`q4_K_M\` | 4,096 | 1 | Marginal" \
  "| 24 GB | \`q4_K_M\` | 8,192 | 1 |" \
  "| 32 GB | \`q5_K_M\` | 8,192 | 2 |" \
  "| 48 GB | \`q6_K\` | 16,384 | 2 |" \
  "| 64 GB | \`q8_0\` | 32,768 | 4 |" \
  "| 96 GB | \`q8_0\` | 32,768 | 6 |" \
  "| 128 GB | \`q8_0\` | 65,536 | 8 |"; do
  grep -F "$row" "$readme" >/dev/null
done

echo "README ZIP usage tests passed"
