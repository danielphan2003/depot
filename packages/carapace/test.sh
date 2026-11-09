#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(carapace --version)
echo "carapace --version: $out"
case $out in *"$DEPOT_VERSION"*) ;; *) exit 1 ;; esac
# A completer generated from the source tree must be there.
carapace --list | grep -q '"git"'
carapace git nushell git ch >/dev/null
# CI probe for #26: a change to one package
