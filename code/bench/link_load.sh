#!/usr/bin/env bash
# Run on the controller checkout (the controller host); no installations on remote hosts.
set -euo pipefail
: # site-specific paths file removed for publication
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec python3 "$SCRIPT_DIR/s1_load.py" "$@"
