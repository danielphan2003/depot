#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(sd --version)
echo "sd --version: $out"
# Upstream tagged 1.1.0 without bumping Cargo.toml, so it reports 1.0.0.
case $out in "sd "*) ;; *) exit 1 ;; esac
# shellcheck disable=SC2016 # sd's capture group, not a shell expansion
[ "$(echo 'hello world' | sd 'w(or)ld' 'f${1}ty')" = 'hello forty' ]
