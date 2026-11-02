#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(ghq --version)
echo "ghq --version: $out"
case $out in *"$DEPOT_VERSION"*) ;; *) exit 1 ;; esac
GHQ_ROOT=$(mktemp -d) ghq list >/dev/null
