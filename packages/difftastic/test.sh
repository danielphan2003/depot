#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(difft --version)
echo "difft --version: $out"
case $out in "Difftastic $DEPOT_VERSION"*) ;; *) exit 1 ;; esac
d=$(mktemp -d)
printf 'fn main() {\n    let x = 1;\n}\n' >"$d/a.rs"
printf 'fn main() {\n    let x = 2;\n}\n' >"$d/b.rs"
difft --color=never "$d/a.rs" "$d/b.rs" | grep -q '2'
