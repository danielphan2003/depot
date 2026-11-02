#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(age-plugin-fido2-hmac --version)
echo "age-plugin-fido2-hmac --version: $out"
[ "$out" = "v$DEPOT_VERSION" ]
