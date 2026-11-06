#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(zellij --version)
echo "zellij --version: $out"
[ "$out" = "zellij $DEPOT_VERSION" ]
zellij setup --check >/dev/null
