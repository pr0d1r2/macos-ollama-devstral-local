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

cli=$test_dir/ollama
cat >"$cli" <<'EOF'
#!/bin/sh
printf '%s|%s\n' "${OLLAMA_HOST-}" "$*" >>"${MOCK_OLLAMA_LOG:?}"
EOF
chmod +x "$cli"

launchctl_log=$test_dir/launchctl.log
ollama_log=$test_dir/ollama.log
plist=$test_dir/agents/service.plist
mkdir -p "$(dirname "$plist")"
printf '%s\n' plist >"$plist"

PATH="$mock_bin:$PATH" HOME="$test_dir/home" OLLAMA_PLIST_PATH="$plist" \
  MOCK_LAUNCHCTL_LOG="$launchctl_log" MOCK_OLLAMA_LOG="$ollama_log" \
  OLLAMA_CLI_PATH="$cli" sh "$repo_dir/uninstall.sh" --remove-model

[ "$(sed -n '1p' "$launchctl_log")" = "unload $plist" ]
[ ! -e "$plist" ]
[ "$(sed -n '1p' "$ollama_log")" = "0.0.0.0:11434|rm devstral" ]

: >"$launchctl_log"
PATH="$mock_bin:$PATH" HOME="$test_dir/home" OLLAMA_PLIST_PATH="$plist" \
  MOCK_LAUNCHCTL_LOG="$launchctl_log" sh "$repo_dir/uninstall.sh" >/dev/null
[ "$(sed -n '1p' "$launchctl_log")" = "unload $plist" ]

if PATH="$mock_bin:$PATH" HOME="$test_dir/home" OLLAMA_PLIST_PATH="$plist" \
  MOCK_LAUNCHCTL_LOG="$launchctl_log" sh "$repo_dir/uninstall.sh" --bad >/dev/null 2>&1; then
  echo "uninstall accepted an invalid option" >&2
  exit 1
fi

echo "uninstall.sh tests passed"
