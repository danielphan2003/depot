#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(starship --version)
echo "starship --version: $out"
case $out in "starship $DEPOT_VERSION"*) ;; *) exit 1 ;; esac
cfg=$(mktemp)
STARSHIP_CONFIG=$cfg starship prompt >/dev/null
rm -f "$cfg"
