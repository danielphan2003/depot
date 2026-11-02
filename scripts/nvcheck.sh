#!/usr/bin/env bash
# nvcheck.sh
#
# Compare each package's version with upstream using nvchecker. Prints one
# "<package> <current> <latest>" line per outdated package. bump.yml runs it
# in a job with a read-only token and hands the lines to open-bump-prs.sh.
# GITHUB_TOKEN, if set, raises GitHub's API rate limit.
source "$(dirname "$0")/lib.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Current versions, in nvchecker's version-file format.
{
  echo '{"version": 2, "data": {'
  sep=''
  for dir in "$DEPOT_ROOT"/packages/*/; do
    name=$(basename "$dir")
    package_env "$name"
    printf '%s"%s": {"version": "%s"}' "$sep" "$name" "$pkg_version"
    sep=$',\n'
  done
  echo '}}'
} >"$tmp/old_ver.json"

{
  printf '[__config__]\noldver = "%s"\nnewver = "%s"\n' "$tmp/old_ver.json" "$tmp/new_ver.json"
  [[ -n ${GITHUB_TOKEN:-} ]] && printf 'keyfile = "%s"\n' "$tmp/keys.toml"
  echo
  cat "$DEPOT_ROOT/nvchecker.toml"
} >"$tmp/nvchecker.toml"
if [[ -n ${GITHUB_TOKEN:-} ]]; then
  (umask 077 && printf '[keys]\ngithub = "%s"\n' "$GITHUB_TOKEN" >"$tmp/keys.toml")
fi

nvchecker --logger json -c "$tmp/nvchecker.toml" >"$tmp/nvchecker.log" ||
  { cat "$tmp/nvchecker.log" >&2; die "nvchecker failed"; }
if grep -q '"level": "error"' "$tmp/nvchecker.log"; then
  cat "$tmp/nvchecker.log" >&2
  die "nvchecker reported errors"
fi
mapfile -t updates < <(nvcmp -c "$tmp/nvchecker.toml" | sed -n 's/^\([^ ]*\) \([^ ]*\) -> \([^ ]*\)$/\1 \2 \3/p')

[[ ${#updates[@]} -eq 0 ]] || printf '%s\n' "${updates[@]}"
