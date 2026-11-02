#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env. A GUI app: check
# the installed pieces and that the binary starts far enough to print help.
set -eu
out=$(QT_QPA_PLATFORM=offscreen freesmlauncher --version 2>&1 || true)
echo "freesmlauncher --version: $out"
case $out in *"$DEPOT_VERSION"*) ;; *) exit 1 ;; esac
[ -f /usr/share/applications/org.freesmlauncher.FreesmLauncher.desktop ]
ls /usr/share/FreesmLauncher/*.jar >/dev/null
