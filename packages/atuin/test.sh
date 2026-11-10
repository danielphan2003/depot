#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(atuin --version)
echo "atuin --version: $out"
# Upstream's release build appends the source commit: "atuin 18.24.6 (c71cd7ba...)".
[ "${out%% (*}" = "atuin $DEPOT_VERSION" ]
atuin init nu >/dev/null
