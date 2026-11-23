#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(rad --version)
echo "rad --version: $out"
case $out in "rad $DEPOT_VERSION "*) ;; *) exit 1 ;; esac
radicle-node --version
command -v git-remote-rad
# Create a profile offline in a throwaway home: no node, no network. The fixed
# seed and passphrase are test values only.
home=$(mktemp -d)
RAD_HOME=$home RAD_PASSPHRASE=depot-test \
  RAD_KEYGEN_SEED=ff00000000000000000000000000000000000000000000000000000000000000 \
  rad auth --alias depot-test </dev/null
did=$(RAD_HOME=$home rad self --did)
echo "rad self --did: $did"
case $did in did:key:z6Mk*) ;; *) exit 1 ;; esac
rm -rf "$home"
