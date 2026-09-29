#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
readme=$repo_dir/README.md

grep -F 'Code → Download ZIP' "$readme" >/dev/null
grep -F 'sh start.sh' "$readme" >/dev/null
grep -F 'ZIP extraction can remove executable bits' "$readme" >/dev/null
grep -F 'waits for Ollama.app' "$readme" >/dev/null
grep -F 'TIER=64 sh start.sh' "$readme" >/dev/null

echo "README ZIP usage tests passed"
