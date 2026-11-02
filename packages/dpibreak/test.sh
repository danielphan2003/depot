#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env. dpibreak has no
# --version; its man page carries v<major>.<minor>, which build.rs stamps in.
set -eu
dpibreak --help | grep -q '^Usage: dpibreak'
man=/usr/share/man/man1/dpibreak.1
[ -f "$man" ] || man=$man.gz
{ zcat -f "$man"; } | grep -q "v${DEPOT_VERSION%.*}"
echo "dpibreak: --help works, man page for v${DEPOT_VERSION%.*}"
