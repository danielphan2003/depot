#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
export FLY_NO_UPDATE_CHECK=1
out=$(flyctl version)
echo "flyctl version: $out"
case $out in *"v$DEPOT_VERSION"*) ;; *) exit 1 ;; esac
fly version >/dev/null
