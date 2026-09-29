#!/bin/sh
set -eu

architecture=$(uname -m)
if [ "$architecture" != arm64 ]; then
  echo "Unsupported architecture: $architecture (this script requires arm64)." >&2
  exit 1
fi
