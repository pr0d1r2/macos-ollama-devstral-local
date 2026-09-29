#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH='' cd -- "$script_dir/.." && pwd)
# shellcheck disable=SC1091
. "$repo_dir/config.sh"

OLLAMA_CLI=${OLLAMA_CLI:-}
if [ -z "$OLLAMA_CLI" ]; then
  if [ -x /Applications/Ollama.app/Contents/Resources/ollama ]; then
    OLLAMA_CLI=/Applications/Ollama.app/Contents/Resources/ollama
  elif command -v ollama >/dev/null 2>&1; then
    OLLAMA_CLI=$(command -v ollama)
  else
    echo "Ollama CLI not found. Install /Applications/Ollama.app or add ollama to PATH." >&2
    exit 1
  fi
fi

if [ ! -x "$OLLAMA_CLI" ]; then
  echo "Ollama CLI is not executable: $OLLAMA_CLI" >&2
  exit 1
fi

launch_agents_dir=${LAUNCH_AGENTS_DIR:-${HOME:?}/Library/LaunchAgents}
logs_dir=${OLLAMA_LOG_DIR:-${HOME:?}/Library/Logs}
label=${OLLAMA_LAUNCHD_LABEL:-com.pr0d1r2.ollama-devstral-local}
plist_path=${OLLAMA_PLIST_PATH:-$launch_agents_dir/$label.plist}
stdout_path=${OLLAMA_STDOUT_LOG:-$logs_dir/ollama-devstral-local.log}
stderr_path=${OLLAMA_STDERR_LOG:-$logs_dir/ollama-devstral-local.error.log}

xml_escape_sed='s/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g'

mkdir -p "$(dirname -- "$plist_path")" "$(dirname -- "$stdout_path")" "$(dirname -- "$stderr_path")"
temporary_plist=$plist_path.tmp.$$
trap 'rm -f "$temporary_plist"' EXIT HUP INT TERM

{
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>'
  printf '%s\n' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
  printf '%s\n' '<plist version="1.0">' '<dict>'
  printf '%s\n' '  <key>Label</key>' "  <string>$(printf '%s' "$label" | sed "$xml_escape_sed")</string>"
  printf '%s\n' '  <key>ProgramArguments</key>' '  <array>'
  printf '%s\n' "    <string>$(printf '%s' "$OLLAMA_CLI" | sed "$xml_escape_sed")</string>" '    <string>serve</string>' '  </array>'
  printf '%s\n' '  <key>EnvironmentVariables</key>' '  <dict>'
  printf '%s\n' '    <key>OLLAMA_HOST</key>' "    <string>$(printf '%s' "0.0.0.0:$PORT" | sed "$xml_escape_sed")</string>"
  printf '%s\n' '    <key>OLLAMA_KEEP_ALIVE</key>' "    <string>$(printf '%s' "$KEEP_ALIVE" | sed "$xml_escape_sed")</string>"
  printf '%s\n' '    <key>OLLAMA_CONTEXT_LENGTH</key>' "    <string>$(printf '%s' "$CTX" | sed "$xml_escape_sed")</string>"
  printf '%s\n' '    <key>OLLAMA_NUM_PARALLEL</key>' "    <string>$(printf '%s' "$NUM_PARALLEL" | sed "$xml_escape_sed")</string>"
  printf '%s\n' '  </dict>'
  printf '%s\n' '  <key>RunAtLoad</key>' '  <true/>'
  printf '%s\n' '  <key>KeepAlive</key>' '  <true/>'
  printf '%s\n' '  <key>StandardOutPath</key>' "  <string>$(printf '%s' "$stdout_path" | sed "$xml_escape_sed")</string>"
  printf '%s\n' '  <key>StandardErrorPath</key>' "  <string>$(printf '%s' "$stderr_path" | sed "$xml_escape_sed")</string>"
  printf '%s\n' '</dict>' '</plist>'
} >"$temporary_plist"
mv "$temporary_plist" "$plist_path"
trap - EXIT HUP INT TERM
printf '%s\n' "$plist_path"
