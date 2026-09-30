#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM

wrapper_dir=$test_dir/wrapper
mock_bin=$test_dir/bin
mkdir -p "$wrapper_dir" "$mock_bin"
cp "$repo_dir/agent-lib.sh" "$wrapper_dir/agent-lib.sh"
cp "$repo_dir/config.sh" "$wrapper_dir/config.sh"

cat >"$mock_bin/curl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"${MOCK_CURL_LOG:?}"
printf '%s\n' '{"data":[{"id":"devstral:latest"}]}'
EOF
chmod +x "$mock_bin/curl"

cat >"$mock_bin/real-agent" <<'EOF'
#!/bin/sh
printf 'args=%s\n' "$*"
cat
exit 23
EOF
chmod +x "$mock_bin/real-agent"

cat >"$wrapper_dir/runner.sh" <<'EOF'
#!/bin/sh
. "$(dirname -- "$0")/agent-lib.sh"
agent_exec real-agent "$@"
EOF
chmod +x "$wrapper_dir/runner.sh"

curl_log=$test_dir/curl.log
system_path=$PATH
if printf 'stdin\n' | PATH="$wrapper_dir:$mock_bin:$system_path" MOCK_CURL_LOG="$curl_log" \
  AGENT_BASE_URL=http://127.0.0.1:11434/v1 "$wrapper_dir/runner.sh" one 'two words' >"$test_dir/output"; then
  echo "agent_exec did not preserve the real binary exit code" >&2
  exit 1
else
  [ "$?" -eq 23 ]
fi
grep -F 'args=one two words' "$test_dir/output" >/dev/null
grep -F 'stdin' "$test_dir/output" >/dev/null
grep -F 'http://127.0.0.1:11434/v1/models' "$curl_log" >/dev/null

if PATH="$wrapper_dir:$mock_bin:$system_path" MOCK_CURL_LOG="$curl_log" AGENT_BASE_URL=http://127.0.0.1:11434/v1 \
  AGENT_MODEL=other "$wrapper_dir/runner.sh" >/dev/null 2>"$test_dir/error"; then
  echo "agent_exec accepted a missing model tag" >&2
  exit 1
fi
grep -F 'Ollama model tag not found' "$test_dir/error" >/dev/null

if PATH="$wrapper_dir:$mock_bin:$system_path" AGENT_BASE_URL=http://127.0.0.1:11434/v1 \
  "$wrapper_dir/runner.sh" >/dev/null 2>"$test_dir/error"; then
  echo "agent_exec accepted a missing binary" >&2
  exit 1
fi

echo "agent-lib.sh tests passed"
