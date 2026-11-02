#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(starship --version)
echo "starship --version: $out"
case $out in "starship $DEPOT_VERSION"*) ;; *) exit 1 ;; esac
STARSHIP_CONFIG=/dev/null starship prompt >/dev/null
