#!/usr/bin/env bash
set -euo pipefail

cd $(dirname "$0") && echo "Creating tarball from $(PWD):"
gtar --create --overwrite --owner=1001 --group=0 --verbose --file=qar-home.tar qar
echo "Done."
