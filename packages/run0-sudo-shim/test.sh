#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(sudo --version)
echo "sudo --version: $out"
[ "$out" = "sudo $DEPOT_VERSION" ]
# run0 is compiled in by absolute path, never looked up in $PATH.
grep -aq /usr/bin/run0 /usr/bin/sudo
# The sudo package is replaced, not installed beside it.
if command -v pacman >/dev/null; then
  if pacman -Q sudo >/dev/null 2>&1; then echo "the sudo package is installed too" >&2; exit 1; fi
  [ "$(pacman -Qoq /usr/bin/sudo)" = run0-sudo-shim ]
fi
