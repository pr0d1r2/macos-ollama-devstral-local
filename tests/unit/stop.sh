#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM

mock_bin=$test_dir/bin
mkdir -p "$mock_bin"
cat >"$mock_bin/launchctl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"${MOCK_LAUNCHCTL_LOG:?}"
exit "${MOCK_LAUNCHCTL_EXIT:-0}"
EOF
chmod +x "$mock_bin/launchctl"

launchctl_log=$test_dir/launchctl.log
output=$test_dir/output

PATH="$mock_bin:$PATH" HOME="$test_dir/home" MOCK_LAUNCHCTL_LOG="$launchctl_log" \
  sh "$repo_dir/stop.sh" >"$output"
grep -E '^unload .*/Library/LaunchAgents/com\.pr0d1r2\.ollama-devstral-local\.plist$' \
  "$launchctl_log" >/dev/null
grep -F 'Unloaded Ollama LaunchAgent:' "$output" >/dev/null

: >"$launchctl_log"
PATH="$mock_bin:$PATH" HOME="$test_dir/home" MOCK_LAUNCHCTL_LOG="$launchctl_log" \
  MOCK_LAUNCHCTL_EXIT=36 sh "$repo_dir/stop.sh" >"$output"
grep -E '^unload .*/Library/LaunchAgents/com\.pr0d1r2\.ollama-devstral-local\.plist$' \
  "$launchctl_log" >/dev/null
grep -F 'Unloaded Ollama LaunchAgent:' "$output" >/dev/null

: >"$launchctl_log"
custom_plist=$test_dir/custom/service.plist
PATH="$mock_bin:$PATH" HOME="$test_dir/home" OLLAMA_PLIST_PATH="$custom_plist" \
  MOCK_LAUNCHCTL_LOG="$launchctl_log" sh "$repo_dir/stop.sh" >/dev/null
grep -F "unload $custom_plist" "$launchctl_log" >/dev/null

echo "stop.sh tests passed"
