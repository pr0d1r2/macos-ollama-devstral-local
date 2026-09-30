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

cat >"$mock_bin/codex" <<'EOF'
#!/bin/sh
printf 'args=%s\n' "$*"
cat
exit 19
EOF
chmod +x "$mock_bin/codex"

if printf 'stdin\n' | HOME="$home_dir" PATH="$mock_bin:$PATH" \
  CODEX_CONFIG_PATH="$home_dir/.codex/config.toml" \
  sh "$repo_dir/agent-codex.sh" 'two words' >"$test_dir/output"; then
  echo "agent-codex.sh did not preserve the real binary exit code" >&2
  exit 1
else
  [ "$?" -eq 19 ]
fi

config_file=$home_dir/.codex/config.toml
[ -f "$config_file" ]
grep -F 'model = "devstral"' "$config_file" >/dev/null
grep -F 'model_provider = "ollama-local"' "$config_file" >/dev/null
grep -F '[model_providers.ollama-local]' "$config_file" >/dev/null
grep -F 'base_url = "http://127.0.0.1:11434/v1"' "$config_file" >/dev/null
grep -F 'wire_api = "responses"' "$config_file" >/dev/null
grep -F 'args=two words' "$test_dir/output" >/dev/null
grep -F 'stdin' "$test_dir/output" >/dev/null

echo "agent-codex.sh tests passed"
