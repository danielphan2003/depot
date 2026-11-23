#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(cib --version)
echo "cib --version: $out"
# Both name the package, not the binary ("radicle-ci-broker 0.32.1@unknown"):
# the crate carries no git checkout, so upstream's build.rs appends @unknown.
case $out in "radicle-ci-broker $DEPOT_VERSION@"*) ;; *) exit 1 ;; esac
out=$(cibtool --version)
echo "cibtool --version: $out"
case $out in "radicle-ci-broker $DEPOT_VERSION@"*) ;; *) exit 1 ;; esac
# Both parse their arguments before touching a config, a database or the node.
cib --help >/dev/null
cibtool --help >/dev/null
