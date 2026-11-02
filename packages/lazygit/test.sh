#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(lazygit --version)
echo "lazygit --version: $out"
case $out in *"version=$DEPOT_VERSION,"*) ;; *) exit 1 ;; esac
