#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM

home_dir=$test_dir/home
mock_bin=$test_dir/bin
mkdir -p "$home_dir" "$mock_bin"

cat >"$mock_bin/curl" <<'EOF'
#!/bin/sh
printf '%s\n' '{"data":[{"id":"devstral"}]}'
EOF
chmod +x "$mock_bin/curl"

cat >"$mock_bin/opencode" <<'EOF'
#!/bin/sh
printf 'args=%s\n' "$*"
cat
exit 19
EOF
chmod +x "$mock_bin/opencode"

if printf 'stdin\n' | HOME="$home_dir" PATH="$mock_bin:$PATH" \
  OPENCODE_CONFIG_PATH="$home_dir/.config/opencode/opencode.json" \
  "$repo_dir/agent-opencode.sh" 'two words' >"$test_dir/output"; then
  echo "agent-opencode.sh did not preserve the real binary exit code" >&2
  exit 1
else
  [ "$?" -eq 19 ]
fi

config_file=$home_dir/.config/opencode/opencode.json
[ -f "$config_file" ]
grep -F '"npm": "@ai-sdk/openai-compatible"' "$config_file" >/dev/null
grep -F '"baseURL": "http://127.0.0.1:11434/v1"' "$config_file" >/dev/null
grep -F '"devstral": {}' "$config_file" >/dev/null
grep -F '"model": "ollama/devstral"' "$config_file" >/dev/null
grep -F 'args=two words' "$test_dir/output" >/dev/null
grep -F 'stdin' "$test_dir/output" >/dev/null

echo "agent-opencode.sh tests passed"
