#!/bin/sh
set -eu

repo_dir=$(cd -- "$(dirname -- "$0")/../.." && pwd)
mock_bin=$(mktemp -d)
trap 'rm -rf "$mock_bin"' EXIT HUP INT TERM

cat >"$mock_bin/uname" <<'EOF'
#!/bin/sh
printf '%s\n' "${MOCK_UNAME:-arm64}"
EOF
chmod +x "$mock_bin/uname"

cat >"$mock_bin/ollama" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$mock_bin/ollama"

cat >"$mock_bin/open" <<'EOF'
#!/bin/sh
if [ -n "${MOCK_OPEN_LOG:-}" ]; then
  printf '%s\n' "$*" >"$MOCK_OPEN_LOG"
fi
EOF
chmod +x "$mock_bin/open"

cat >"$mock_bin/osascript" <<'EOF'
#!/bin/sh
if [ -n "${MOCK_OSASCRIPT_LOG:-}" ]; then
  printf '%s\n' "$*" >"$MOCK_OSASCRIPT_LOG"
fi
if [ "${MOCK_OSASCRIPT_FAIL:-0}" = 1 ]; then
  exit 1
fi
EOF
chmod +x "$mock_bin/osascript"

cat >"$mock_bin/launchctl" <<'EOF'
#!/bin/sh
if [ -n "${MOCK_LAUNCHCTL_LOG:-}" ]; then
  printf '%s\n' "$*" >>"$MOCK_LAUNCHCTL_LOG"
fi
EOF
chmod +x "$mock_bin/launchctl"

cat >"$mock_bin/sleep" <<'EOF'
#!/bin/sh
mkdir -p "${MOCK_APP_ON_SLEEP:?}/Contents/Resources"
cat >"${MOCK_APP_ON_SLEEP}/Contents/Resources/ollama" <<'INNER_EOF'
#!/bin/sh
exit 0
INNER_EOF
chmod +x "${MOCK_APP_ON_SLEEP}/Contents/Resources/ollama"
EOF
chmod +x "$mock_bin/sleep"

app_dir=$(mktemp -d)
trap 'rm -rf "$mock_bin" "$app_dir"' EXIT HUP INT TERM
mkdir -p "$app_dir/Contents/Resources"
cat >"$app_dir/Contents/Resources/ollama" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$app_dir/Contents/Resources/ollama"

launchctl_log="$mock_bin/launchctl.log"

PATH="$mock_bin:$PATH" OLLAMA_APP="$app_dir" MOCK_OSASCRIPT_LOG="$mock_bin/osascript.log" \
  MOCK_LAUNCHCTL_LOG="$launchctl_log" HOME="$mock_bin/home" LAUNCH_AGENTS_DIR="$mock_bin/agents" \
  MOCK_UNAME=arm64 sh "$repo_dir/start.sh"

grep -E '^unload .*/com\.pr0d1r2\.ollama-devstral-local\.plist$' "$launchctl_log" >/dev/null
grep -E '^load .*/com\.pr0d1r2\.ollama-devstral-local\.plist$' "$launchctl_log" >/dev/null
plist=$(sed -n 's/^load //p' "$launchctl_log")
[ -f "$plist" ]

: >"$launchctl_log"
PATH="$mock_bin:$PATH" OLLAMA_APP="$app_dir" MOCK_LAUNCHCTL_LOG="$launchctl_log" \
  HOME="$mock_bin/home" LAUNCH_AGENTS_DIR="$mock_bin/agents" MOCK_UNAME=arm64 \
  sh "$repo_dir/start.sh"
grep -E '^unload ' "$launchctl_log" >/dev/null
grep -E '^load ' "$launchctl_log" >/dev/null

grep -F 'delete login item "Ollama"' "$mock_bin/osascript.log" >/dev/null 2>&1 || {
  echo "start.sh did not attempt to disable Ollama login item" >&2
  exit 1
}

PATH="$mock_bin:$PATH" OLLAMA_APP="$app_dir" MOCK_OSASCRIPT_FAIL=1 HOME="$mock_bin/home" \
  LAUNCH_AGENTS_DIR="$mock_bin/agents" MOCK_LAUNCHCTL_LOG="$launchctl_log" MOCK_UNAME=arm64 \
  sh "$repo_dir/start.sh" >"$mock_bin/autostart-fallback-output"
grep -F 'Could not automatically disable Ollama.app menubar autostart' "$mock_bin/autostart-fallback-output" >/dev/null
grep -F 'System Settings' "$mock_bin/autostart-fallback-output" >/dev/null

if PATH="$mock_bin:$PATH" MOCK_UNAME=x86_64 sh "$repo_dir/start.sh" 2>"$mock_bin/error"; then
  echo "start.sh accepted a non-arm64 architecture" >&2
  exit 1
fi

grep -F 'Unsupported architecture: x86_64' "$mock_bin/error" >/dev/null
grep -F 'requires arm64' "$mock_bin/error" >/dev/null

PATH="$mock_bin:$PATH" OLLAMA_APP="$app_dir" HOME="$mock_bin/home" \
  LAUNCH_AGENTS_DIR="$mock_bin/agents" MOCK_LAUNCHCTL_LOG="$launchctl_log" MOCK_UNAME=arm64 \
  sh -c '. "$1"; [ "$OLLAMA_CLI" = "$2/Contents/Resources/ollama" ]' \
  sh "$repo_dir/start.sh" "$app_dir"

path_app_dir=$(mktemp -d)
PATH="$mock_bin:$PATH" OLLAMA_APP="$path_app_dir" HOME="$mock_bin/home" \
  LAUNCH_AGENTS_DIR="$mock_bin/agents" MOCK_LAUNCHCTL_LOG="$launchctl_log" MOCK_UNAME=arm64 \
  sh -c '. "$1"; [ "$OLLAMA_CLI" = "$(command -v ollama)" ]' \
  sh "$repo_dir/start.sh"

install_dir=$(mktemp -d)
open_log="$mock_bin/open.log"
PATH="$mock_bin:$PATH" OLLAMA_APP="$install_dir/Ollama.app" \
  MOCK_APP_ON_SLEEP="$install_dir/Ollama.app" MOCK_OPEN_LOG="$open_log" \
  OLLAMA_INSTALL_POLL_INTERVAL=0 HOME="$mock_bin/home" LAUNCH_AGENTS_DIR="$mock_bin/agents" \
  MOCK_LAUNCHCTL_LOG="$launchctl_log" MOCK_UNAME=arm64 sh "$repo_dir/start.sh" \
  >"$mock_bin/install-output"
grep -F 'https://ollama.com/download' "$open_log" >/dev/null
grep -F 'Install Ollama for macOS' "$mock_bin/install-output" >/dev/null
grep -F 'Ollama.app detected' "$mock_bin/install-output" >/dev/null
echo "start.sh architecture guard tests passed"
