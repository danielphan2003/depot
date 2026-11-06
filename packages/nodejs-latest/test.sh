#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(node --version)
echo "node --version: $out"
[ "$out" = "v$DEPOT_VERSION" ]
[ "$(node -e 'console.log(6 * 7)')" = 42 ]
npm --version
npx --version
