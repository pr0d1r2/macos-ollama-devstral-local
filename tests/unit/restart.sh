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
if [ "${1:-}" = unload ]; then
  exit "${MOCK_UNLOAD_EXIT:-0}"
fi
exit "${MOCK_LOAD_EXIT:-0}"
EOF
chmod +x "$mock_bin/launchctl"

launchctl_log=$test_dir/launchctl.log
output=$test_dir/output
test_home=$test_dir/${TEST_HOME_NAME:-home}
default_plist=$test_home/Library/LaunchAgents/com.pr0d1r2.ollama-devstral-local.plist

PATH="$mock_bin:$PATH" HOME="$test_home" MOCK_LAUNCHCTL_LOG="$launchctl_log" \
  sh "$repo_dir/restart.sh" >"$output"
[ "$(sed -n '1p' "$launchctl_log")" = "unload $default_plist" ]
[ "$(sed -n '2p' "$launchctl_log")" = "load $default_plist" ]
grep -F 'Restarted Ollama LaunchAgent:' "$output" >/dev/null

: >"$launchctl_log"
PATH="$mock_bin:$PATH" HOME="$test_home" MOCK_LAUNCHCTL_LOG="$launchctl_log" \
  MOCK_UNLOAD_EXIT=36 sh "$repo_dir/restart.sh" >/dev/null
[ "$(sed -n '2p' "$launchctl_log")" = "load $default_plist" ]

: >"$launchctl_log"
custom_plist=$test_dir/custom/service.plist
PATH="$mock_bin:$PATH" HOME="$test_home" OLLAMA_PLIST_PATH="$custom_plist" \
  MOCK_LAUNCHCTL_LOG="$launchctl_log" sh "$repo_dir/restart.sh" >/dev/null
grep -F "unload $custom_plist" "$launchctl_log" >/dev/null
grep -F "load $custom_plist" "$launchctl_log" >/dev/null

: >"$launchctl_log"
if PATH="$mock_bin:$PATH" HOME="$test_home" MOCK_LAUNCHCTL_LOG="$launchctl_log" \
  MOCK_LOAD_EXIT=42 sh "$repo_dir/restart.sh" >/dev/null 2>&1; then
  echo "restart.sh accepted a failed launchctl load" >&2
  exit 1
fi
[ "$(sed -n '2p' "$launchctl_log")" = "load $default_plist" ]

echo "restart.sh tests passed"
