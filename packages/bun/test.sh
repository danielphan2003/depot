#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(bun --version)
echo "bun --version: $out"
[ "$out" = "$DEPOT_VERSION" ]
[ "$(bun -e 'console.log(6 * 7)')" = 42 ]
[ "$(bunx --version)" = "$DEPOT_VERSION" ]
