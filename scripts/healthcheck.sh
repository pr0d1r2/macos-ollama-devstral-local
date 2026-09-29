#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
# shellcheck disable=SC1091
. "$script_dir/config.sh"

lan_ip=${LAN_IP:-}
if [ -z "$lan_ip" ]; then
  for interface in en0 en1; do
    if lan_ip=$(ipconfig getifaddr "$interface" 2>/dev/null) && [ -n "$lan_ip" ]; then
      break
    fi
    lan_ip=
  done
fi

if [ -z "$lan_ip" ]; then
  echo "Could not determine a LAN IP address for the Ollama healthcheck." >&2
  exit 1
fi

healthcheck_url=http://$lan_ip:$PORT/api/tags
echo "Checking Ollama at $healthcheck_url"
if ! curl -fsS "$healthcheck_url" >/dev/null; then
  echo "Ollama healthcheck failed at $healthcheck_url." >&2
  exit 1
fi
echo "Ollama healthcheck passed."
