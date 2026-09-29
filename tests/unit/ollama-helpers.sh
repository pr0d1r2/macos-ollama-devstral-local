#!/bin/sh
set -eu
repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
mock_bin=$(mktemp -d)
trap 'rm -rf "$mock_bin"' EXIT HUP INT TERM
cat >"$mock_bin/curl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"${MOCK_CURL_LOG:?}"
case "$*" in
  *api/generate) printf '%s\n' '{"response":"OK","total_duration":123,"eval_count":7}' ;;
  *api/show) printf '%s\n' '{"name":"devstral"}' ;;
  *api/ps) printf '%s\n' '{"models":[]}' ;;
  *api/tags) printf '%s\n' '{"models":[{"name":"devstral:latest"}]}' ;;
esac
EOF
chmod +x "$mock_bin/curl"
log=$mock_bin/curl.log
run_helper() { PATH="$mock_bin:$PATH" MOCK_CURL_LOG="$log" MODEL=devstral OLLAMA_HOST=192.0.2.10:11434 sh "$@"; }
run_helper "$repo_dir/scripts/get-model.sh" custom >"$mock_bin/get-model.out"
grep -F 'http://192.0.2.10:11434/api/show' "$log" >/dev/null
grep -F '"name":"custom"' "$log" >/dev/null
run_helper "$repo_dir/scripts/status.sh" >"$mock_bin/status.out"
grep -F '/api/ps' "$log" >/dev/null
run_helper "$repo_dir/scripts/models.sh" >"$mock_bin/models.out"
grep -F '/api/tags' "$log" >/dev/null
run_helper "$repo_dir/scripts/test.sh" 'say hello' >"$mock_bin/test.out" 2>"$mock_bin/test.err"
grep -F '"stream":false' "$log" >/dev/null
grep -F 'total_duration=123' "$mock_bin/test.err" >/dev/null
grep -F 'eval_count=7' "$mock_bin/test.err" >/dev/null
run_helper "$repo_dir/scripts/prompt.sh" 'say hello' >"$mock_bin/prompt.out" 2>"$mock_bin/prompt.err"
grep -Fx 'OK' "$mock_bin/prompt.out" >/dev/null
grep -F 'total_duration=123' "$mock_bin/prompt.err" >/dev/null
echo "ollama helper tests passed"
