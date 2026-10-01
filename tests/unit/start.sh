#!/bin/sh
set -eu

repo_dir=$(cd -- "$(dirname -- "$0")/../.." && pwd)
mock_bin=$(mktemp -d)
trap 'rm -rf "$mock_bin"' EXIT HUP INT TERM

# A zip/unzip round trip may drop the executable bit. The documented
# `sh start.sh` bootstrap must repair it for a subsequent direct invocation.
exec_bit_test_dir=$(mktemp -d)
exec_bit_mock_bin=$(mktemp -d)
trap 'rm -rf "$mock_bin" "$exec_bit_test_dir" "$exec_bit_mock_bin"' EXIT HUP INT TERM
cp "$repo_dir/start.sh" "$exec_bit_test_dir/start.sh"
chmod 644 "$exec_bit_test_dir/start.sh"
# Stop at the architecture guard after the entrypoint repairs its mode. This
# must not open the real download page or wait for Ollama.app on the host.
cat >"$exec_bit_mock_bin/uname" <<'EOF'
#!/bin/sh
printf '%s\n' x86_64
EOF
chmod +x "$exec_bit_mock_bin/uname"
PATH="$exec_bit_mock_bin:$PATH" sh "$exec_bit_test_dir/start.sh" 2>/dev/null || true
[ -x "$exec_bit_test_dir/start.sh" ]

cat >"$mock_bin/uname" <<'EOF'
#!/bin/sh
printf '%s\n' "${MOCK_UNAME:-arm64}"
EOF
chmod +x "$mock_bin/uname"

cat >"$mock_bin/ollama" <<'EOF'
#!/bin/sh
if [ "${1:-}" = list ]; then
  if [ "${MOCK_MODEL_PRESENT:-0}" = 1 ]; then
    if [ "${MODEL:-}" = 'foo.bar' ]; then
      printf '%s\n' 'NAME ID SIZE MODIFIED' 'fooXbar abc 1 GB now'
    else
      printf '%s\n' 'NAME ID SIZE MODIFIED' 'devstral:latest abc 1 GB now'
    fi
  else
    printf '%s\n' 'NAME ID SIZE MODIFIED'
  fi
elif [ "${1:-}" = pull ]; then
  printf 'pull %s\n' "${2:-}" >>"${MOCK_PULL_LOG:-/dev/null}"
fi
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

cat >"$mock_bin/curl" <<'EOF'
#!/bin/sh
if [ -n "${MOCK_CURL_LOG:-}" ]; then
  printf '%s\n' "$*" >>"$MOCK_CURL_LOG"
fi
exit "${MOCK_CURL_EXIT:-0}"
EOF
chmod +x "$mock_bin/curl"

cat >"$mock_bin/ipconfig" <<'EOF'
#!/bin/sh
printf '%s\n' '192.0.2.10'
EOF
chmod +x "$mock_bin/ipconfig"

cat >"$mock_bin/scutil" <<'EOF'
#!/bin/sh
printf '%s\n' 'test-mac'
EOF
chmod +x "$mock_bin/scutil"

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
if [ "${1:-}" = list ]; then
  if [ "${MOCK_MODEL_PRESENT:-0}" = 1 ]; then
    if [ "${MODEL:-}" = 'foo.bar' ]; then
      printf '%s\n' 'NAME ID SIZE MODIFIED' 'fooXbar abc 1 GB now'
    else
      printf '%s\n' 'NAME ID SIZE MODIFIED' 'devstral:latest abc 1 GB now'
    fi
  else
    printf '%s\n' 'NAME ID SIZE MODIFIED'
  fi
elif [ "${1:-}" = pull ]; then
  printf 'pull %s\n' "${2:-}" >>"${MOCK_PULL_LOG:-/dev/null}"
fi
exit 0
EOF
chmod +x "$app_dir/Contents/Resources/ollama"

launchctl_log="$mock_bin/launchctl.log"
pull_log="$mock_bin/pull.log"
curl_log="$mock_bin/curl.log"

PATH="$mock_bin:$PATH" OLLAMA_APP="$app_dir" MOCK_OSASCRIPT_LOG="$mock_bin/osascript.log" \
  MOCK_LAUNCHCTL_LOG="$launchctl_log" HOME="$mock_bin/home" LAUNCH_AGENTS_DIR="$mock_bin/agents" \
  MOCK_UNAME=arm64 MOCK_PULL_LOG="$pull_log" MOCK_CURL_LOG="$curl_log" sh "$repo_dir/start.sh" >"$mock_bin/start-output"

grep -F 'http://192.0.2.10:11434/api/tags' "$curl_log" >/dev/null
grep -F 'Ollama endpoint: http://test-mac.local:11434' "$mock_bin/start-output" >/dev/null
grep -F 'pull devstral' "$pull_log" >/dev/null
grep -F 'api/generate' "$curl_log" >/dev/null
grep -F 'stream":false' "$curl_log" >/dev/null
grep -F 'keep_alive":-1' "$curl_log" >/dev/null

grep -E '^unload .*/com\.pr0d1r2\.ollama-devstral-local\.plist$' "$launchctl_log" >/dev/null
grep -E '^load .*/com\.pr0d1r2\.ollama-devstral-local\.plist$' "$launchctl_log" >/dev/null
plist=$(sed -n 's/^load //p' "$launchctl_log")
[ -f "$plist" ]

: >"$launchctl_log"
PATH="$mock_bin:$PATH" OLLAMA_APP="$app_dir" MOCK_LAUNCHCTL_LOG="$launchctl_log" \
  MOCK_PULL_LOG="$pull_log" MOCK_MODEL_PRESENT=1 HOME="$mock_bin/home" \
  LAUNCH_AGENTS_DIR="$mock_bin/agents" MOCK_UNAME=arm64 MOCK_CURL_LOG="$curl_log" \
  sh "$repo_dir/start.sh"
grep -E '^unload ' "$launchctl_log" >/dev/null
grep -E '^load ' "$launchctl_log" >/dev/null
[ "$(wc -l <"$pull_log")" -eq 1 ]

: >"$curl_log"
PATH="$mock_bin:$PATH" OLLAMA_APP="$app_dir" KEEP_ALIVE=30 MOCK_MODEL_PRESENT=1 \
  HOME="$mock_bin/home" LAUNCH_AGENTS_DIR="$mock_bin/agents" \
  MOCK_LAUNCHCTL_LOG="$launchctl_log" MOCK_CURL_LOG="$curl_log" MOCK_UNAME=arm64 \
  sh "$repo_dir/start.sh"
grep -F 'keep_alive":30' "$curl_log" >/dev/null

custom_pull_log="$mock_bin/custom-pull.log"
PATH="$mock_bin:$PATH" OLLAMA_APP="$app_dir" MODEL='foo.bar' MOCK_LAUNCHCTL_LOG="$launchctl_log" \
  MOCK_PULL_LOG="$custom_pull_log" MOCK_MODEL_PRESENT=1 HOME="$mock_bin/home" \
  LAUNCH_AGENTS_DIR="$mock_bin/agents" MOCK_UNAME=arm64 MOCK_CURL_LOG="$curl_log" \
  sh "$repo_dir/start.sh"
[ "$(wc -l <"$custom_pull_log")" -eq 1 ]

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
