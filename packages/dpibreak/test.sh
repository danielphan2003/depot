#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env. dpibreak has no
# --version, and container images skip man pages, so check the help and that
# the man page is in the package.
set -eu
dpibreak --help | grep -q '^Usage: dpibreak'
if command -v pacman >/dev/null; then
  pacman -Qlq dpibreak | grep -q '/man1/dpibreak\.1'
elif command -v rpm >/dev/null; then
  rpm -ql dpibreak | grep -q '/man1/dpibreak\.1'
fi
echo "dpibreak $DEPOT_VERSION: --help works"
