#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(custota-tool --version)
echo "custota-tool --version: $out"
case $out in *"v$DEPOT_VERSION"*) ;; *) exit 1 ;; esac
