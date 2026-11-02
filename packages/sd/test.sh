#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(sd --version)
echo "sd --version: $out"
[ "$out" = "sd $DEPOT_VERSION" ]
# shellcheck disable=SC2016 # sd's capture group, not a shell expansion
[ "$(echo 'hello world' | sd 'w(or)ld' 'f${1}ty')" = 'hello forty' ]
