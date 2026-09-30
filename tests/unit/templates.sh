#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
templates_dir=$repo_dir/templates
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM

for template in opencode.json pi.models.json codex.config.toml; do
  [ -f "$templates_dir/$template" ]
  grep -F '__BASE_URL__' "$templates_dir/$template" >/dev/null
  grep -F '__MODEL__' "$templates_dir/$template" >/dev/null
done

# Exercise the same POSIX sed substitution contract used by the wrappers.
for template in opencode.json pi.models.json codex.config.toml; do
  sed -e 's|__BASE_URL__|http://127.0.0.1:11434/v1|g' \
    -e 's|__MODEL__|devstral|g' "$templates_dir/$template" >"$test_dir/$template"
  if grep -E '__BASE_URL__|__MODEL__' "$test_dir/$template" >/dev/null; then
    exit 1
  fi
done

grep -F '"baseURL": "http://127.0.0.1:11434/v1"' "$test_dir/opencode.json" >/dev/null
grep -F '"model": "ollama/devstral"' "$test_dir/opencode.json" >/dev/null
grep -F 'base_url = "http://127.0.0.1:11434/v1"' "$test_dir/codex.config.toml" >/dev/null
grep -F 'wire_api = "responses"' "$test_dir/codex.config.toml" >/dev/null
grep -F '"baseUrl": "http://127.0.0.1:11434/v1"' "$test_dir/pi.models.json" >/dev/null
grep -F '{"id": "devstral"}' "$test_dir/pi.models.json" >/dev/null

echo "template substitution tests passed"
