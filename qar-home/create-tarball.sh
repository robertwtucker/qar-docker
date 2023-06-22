#!/usr/bin/env bash
set -euo pipefail

# Setup
cd "$(dirname "$0")"
echo "Creating tarball from $(PWD)..."

# Add a simple version stamp
TAG="$(awk -F= '/^tag/{print $2}' .release)"
echo "Tagged version is ${TAG}"
awk -F. '{print "0." $2 "." $3}' <<<"${TAG}" >qar/.version

# Create the tarball
gtar --create --overwrite --owner=1001 --group=0 --verbose --file=qar-home.tar qar
echo "Done."
