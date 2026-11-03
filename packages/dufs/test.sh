#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(dufs --version)
echo "dufs --version: $out"
[ "$out" = "dufs $DEPOT_VERSION" ]
