#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM

cli=$test_dir/ollama
printf '%s\n' '#!/bin/sh' >"$cli"
chmod +x "$cli"

HOME=$test_dir OLLAMA_CLI=$cli TIER=24 LAUNCH_AGENTS_DIR=$test_dir/agents \
  OLLAMA_LOG_DIR=$test_dir/logs sh "$repo_dir/scripts/gen-plist.sh" >"$test_dir/output"
plist=$(cat "$test_dir/output")
[ -f "$plist" ]
grep -F '<string>serve</string>' "$plist" >/dev/null
grep -F '<string>0.0.0.0:11434</string>' "$plist" >/dev/null
grep -F '<string>-1</string>' "$plist" >/dev/null
grep -F '<string>8192</string>' "$plist" >/dev/null
grep -F '<string>2</string>' "$plist" >/dev/null
grep -F '<key>RunAtLoad</key>' "$plist" >/dev/null
grep -F '<key>KeepAlive</key>' "$plist" >/dev/null
grep -F '<key>StandardOutPath</key>' "$plist" >/dev/null
grep -F '<key>StandardErrorPath</key>' "$plist" >/dev/null

HOME=$test_dir OLLAMA_CLI=$cli OLLAMA_HOST=192.0.2.10:12345 \
  LAUNCH_AGENTS_DIR=$test_dir/custom-agents OLLAMA_LOG_DIR=$test_dir/custom-logs \
  sh "$repo_dir/scripts/gen-plist.sh" >"$test_dir/custom-output"
custom_plist=$(cat "$test_dir/custom-output")
grep -F '<string>192.0.2.10:12345</string>' "$custom_plist" >/dev/null

if command -v xmllint >/dev/null 2>&1; then
  xmllint --noout "$plist"
fi
echo "gen-plist.sh tests passed"
