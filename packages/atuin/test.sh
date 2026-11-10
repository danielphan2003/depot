#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env.
set -eu
out=$(atuin --version)
echo "atuin --version: $out"
# Upstream's release build appends the source commit: "atuin 18.24.6 (c71cd7ba...)".
[ "${out%% (*}" = "atuin $DEPOT_VERSION" ]
# The integration is why the package exists: when nushell is installed, its
# output must parse (an older atuin's `job spawn -t` failed nu-check).
if command -v nu >/dev/null; then
  script=$(mktemp)
  atuin init nu >"$script"
  [ "$(nu -n -c "nu-check '$script'")" = true ]
  rm -f "$script"
else
  atuin init nu >/dev/null
fi
