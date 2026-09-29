#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
mock_bin=$(mktemp -d)
trap 'rm -rf "$mock_bin"' EXIT HUP INT TERM

cat >"$mock_bin/ipconfig" <<'EOF'
#!/bin/sh
printf '%s\n' "${MOCK_LAN_IP:-192.0.2.10}"
EOF
chmod +x "$mock_bin/ipconfig"

cat >"$mock_bin/curl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"${MOCK_CURL_LOG:?}"
exit "${MOCK_CURL_EXIT:-0}"
EOF
chmod +x "$mock_bin/curl"

curl_log=$mock_bin/curl.log
PATH="$mock_bin:$PATH" MOCK_CURL_LOG="$curl_log" \
  sh "$repo_dir/scripts/healthcheck.sh"
grep -F -- 'http://192.0.2.10:11434/api/tags' "$curl_log" >/dev/null

: >"$curl_log"
PATH="$mock_bin:$PATH" LAN_IP=198.51.100.7 PORT=12345 MOCK_CURL_LOG="$curl_log" \
  sh "$repo_dir/scripts/healthcheck.sh"
grep -F -- 'http://198.51.100.7:12345/api/tags' "$curl_log" >/dev/null

if PATH="$mock_bin:$PATH" LAN_IP=198.51.100.7 MOCK_CURL_LOG="$curl_log" \
  MOCK_CURL_EXIT=7 sh "$repo_dir/scripts/healthcheck.sh" >/dev/null 2>&1; then
  echo "healthcheck accepted a failed curl" >&2
  exit 1
fi

echo "healthcheck.sh tests passed"
