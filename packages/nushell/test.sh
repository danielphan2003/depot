#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(nu --version)
echo "nu --version: $out"
[ "$out" = "$DEPOT_VERSION" ]
[ "$(nu -n -c '[1 2 3] | math sum')" = 6 ]
