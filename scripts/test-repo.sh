#!/usr/bin/env bash
# test-repo.sh <target> <pkgdir> <root>
#
# Turn freshly built packages into a repository signed with a throwaway key,
# so pull requests exercise the same signing and index steps as publish.sh
# without the real key. Writes the public key to <root>/depot-test.asc.
source "$(dirname "$0")/lib.sh"

[[ $# -eq 3 ]] || die "usage: test-repo.sh <target> <pkgdir> <root>"
target_info "$1"
mkdir -p "$3"
root=$(cd "$3" && pwd)

"$DEPOT_ROOT/scripts/repo-tools.sh" "$1"
GNUPGHOME=$(mktemp -d)
export GNUPGHOME
gpg --batch --quiet --passphrase '' --quick-gen-key 'depot test key (throwaway)' ed25519 sign 1d
DEPOT_KEY=$(gpg --with-colons --list-secret-keys | awk -F: '$1=="fpr"{print $10; exit}')
export DEPOT_KEY
gpg --batch --armor --export "$DEPOT_KEY" >"$root/depot-test.asc"

shopt -s nullglob
new=()
for file in "$2"/*; do
  check_package "$file"
  dest=$root/$(pkg_dest "$file")
  mkdir -p "${dest%/*}"
  cp "$file" "$dest"
  new+=("$dest")
done
[[ ${#new[@]} -gt 0 ]] || die "no packages in $2"
"$DEPOT_ROOT/scripts/repo.sh" sign "$1" "${new[@]}"
"$DEPOT_ROOT/scripts/repo.sh" index "$1" "$root"
log "test repository for $1 in $root"
