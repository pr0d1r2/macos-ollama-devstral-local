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

PATH="$mock_bin:$PATH" MOCK_UNAME=arm64 sh "$repo_dir/start.sh"

if PATH="$mock_bin:$PATH" MOCK_UNAME=x86_64 sh "$repo_dir/start.sh" 2>"$mock_bin/error"; then
  echo "start.sh accepted a non-arm64 architecture" >&2
  exit 1
fi

grep -F 'Unsupported architecture: x86_64' "$mock_bin/error" >/dev/null
grep -F 'requires arm64' "$mock_bin/error" >/dev/null
echo "start.sh architecture guard tests passed"
