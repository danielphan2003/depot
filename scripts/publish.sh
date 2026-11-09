#!/usr/bin/env bash
# publish.sh <target> <pkgdir>
#
# Merge freshly built packages into the published repository for <target> and
# upload it. Needs DEPOT_SIGNING_KEY (armored secret key) and
# DEPOT_UPLOAD_TOKEN (the Worker's bearer token) in the environment, and the
# tools from repo-tools.sh, installed in an earlier step without them.
#
# <pkgdir> holds what this run built, which may be only the packages a change
# touched: every other published package stays as it is.
#
# Published files are immutable: a package file whose name is already in the
# bucket is kept, and the new build of it is dropped. Changing a published
# package therefore needs a new version or release (scripts/bump-release.sh).
# For each package it keeps the newest two versions, so a machine can roll
# back one release, and it drops packages that no longer have a recipe.
#
# Everything downloaded from the bucket is verified against the published
# key before it is signed again or listed in an index, so the upload token
# alone cannot get a file signed.
#
# DEPOT_RESIGN=1 re-signs every kept package (key rotation; downloaded files
# are then verified against keys/depot-previous.asc as well).
# DEPOT_WITHDRAW="<file> ..." removes those package files from the repository.
source "$(dirname "$0")/lib.sh"

[[ $# -eq 2 ]] || die "usage: publish.sh <target> <pkgdir>"
target=$1
target_info "$target"
pkgdir=$(cd "$2" && pwd)
: "${DEPOT_SIGNING_KEY:?DEPOT_SIGNING_KEY is not set}"
: "${DEPOT_UPLOAD_TOKEN:?DEPOT_UPLOAD_TOKEN is not set}"
readonly keep=2

work=$(mktemp -d)
chmod 700 "$work"
root=$work/root
mkdir -p "$root"
auth=$work/auth-header
printf 'Authorization: Bearer %s\n' "$DEPOT_UPLOAD_TOKEN" >"$auth"
unset DEPOT_UPLOAD_TOKEN

# Import the signing key and check that it is the key in keys/depot.asc,
# which machines trust.
GNUPGHOME=$work/gnupg
export GNUPGHOME
mkdir -m 700 "$GNUPGHOME"
printf '%s\n' "$DEPOT_SIGNING_KEY" | gpg --batch --quiet --import
unset DEPOT_SIGNING_KEY
DEPOT_KEY=$(gpg --with-colons --list-secret-keys | awk -F: '$1=="fpr"{print $10; exit}')
export DEPOT_KEY
expected=$(key_fingerprint "$DEPOT_ROOT/keys/depot.asc")
[[ $DEPOT_KEY == "$expected" ]] ||
  die "signing key $DEPOT_KEY is not the published key $expected (keys/depot.asc)"

# A keyring of the keys a downloaded file may be signed with: the current
# key, plus the previous one during a rotation.
trusted=("$DEPOT_ROOT/keys/depot.asc")
[[ -f $DEPOT_ROOT/keys/depot-previous.asc ]] && trusted+=("$DEPOT_ROOT/keys/depot-previous.asc")
for key in "${trusted[@]}"; do key_fingerprint "$key" >/dev/null; done
verify_home=$work/verify
mkdir -m 700 "$verify_home"
cat "${trusted[@]}" | gpg --homedir "$verify_home" --batch --quiet --import
gpg --homedir "$verify_home" --batch --export >"$work/trusted.gpg"
if [[ $family == fedora ]]; then
  rpmdb=$work/rpmdb
  mkdir -p "$rpmdb"
  for key in "${trusted[@]}"; do rpmkeys --dbpath "$rpmdb" --import "$key"; done
fi

# remote_list <prefix>: "<key> <etag>" for every object under prefix.
remote_list() {
  local cursor='' page
  while :; do
    page=$(curl -fsS --retry 3 -H @"$auth" -G "$DEPOT_URL/" \
      --data-urlencode list=1 --data-urlencode "prefix=$1" --data-urlencode "cursor=$cursor")
    jq -r '.objects[] | "\(.key) \(.etag)"' <<<"$page"
    cursor=$(jq -r '.cursor // empty' <<<"$page")
    [[ -n $cursor ]] || break
  done
}

declare -A remote
for prefix in "${prefixes[@]}" depot.asc; do
  while read -r k etag; do remote[$k]=$etag; done < <(remote_list "$prefix")
done

is_package() {
  case $1 in
    *.pkg.tar.zst | *.pkg.tar.zst.sig | *.deb | *.rpm) return 0 ;;
  esac
  return 1
}

# 1. Mirror the published packages and verify each one.
fetch() {
  mkdir -p "$root/$(dirname "$1")"
  curl -fsS --retry 3 -o "$root/$1" "$DEPOT_URL/$1"
}

# Debian packages are not signed themselves: check them against the hashes
# in the published Packages file, whose hash is in the signed InRelease.
declare -A deb_sha
if [[ $family == debian && -n ${remote[debian/dists/$codename/InRelease]:-} ]]; then
  dist=debian/dists/$codename
  fetch "$dist/InRelease"
  gpgv --keyring "$work/trusted.gpg" --output "$work/Release" "$root/$dist/InRelease" 2>/dev/null ||
    die "$dist/InRelease does not verify against the trusted keys"
  fetch "$dist/main/binary-amd64/Packages"
  want=$(awk '/^SHA256:/{s=1;next} /^[^ ]/{s=0} s && $3=="main/binary-amd64/Packages"{print $1}' "$work/Release")
  echo "$want  $root/$dist/main/binary-amd64/Packages" | sha256sum -c --quiet - ||
    die "$dist/main/binary-amd64/Packages does not match InRelease"
  while read -r f h; do deb_sha[debian/$f]=$h; done < <(
    awk '/^Filename:/{f=$2} /^SHA256:/{print f, $2}' "$root/$dist/main/binary-amd64/Packages")
  rm -f "$root/$dist/InRelease" "$root/$dist/main/binary-amd64/Packages"
fi

declare -A withdrawn matched
for f in ${DEPOT_WITHDRAW:-}; do
  [[ $f =~ ^[A-Za-z0-9._+~:-]+$ ]] || die "DEPOT_WITHDRAW: not a file name: $f"
  withdrawn[$f]=1
done

for k in "${!remote[@]}"; do
  is_package "$k" || continue
  [[ $k == *.sig ]] && continue
  # A withdrawn file is not downloaded, so the sync below deletes it, even
  # one that fails verification (a planted file).
  if [[ -n ${withdrawn[${k##*/}]:-} ]]; then
    log "withdrawing $k"
    matched[${k##*/}]=1
    continue
  fi
  fetch "$k"
  case $family in
    arch)
      [[ -n ${remote[$k.sig]:-} ]] || die "$k has no signature in the bucket"
      fetch "$k.sig"
      gpgv --keyring "$work/trusted.gpg" "$root/$k.sig" "$root/$k" 2>/dev/null ||
        die "$k does not verify against the trusted keys"
      ;;
    debian)
      [[ -n ${deb_sha[$k]:-} ]] || die "$k is in the bucket but not in the signed Packages file"
      echo "${deb_sha[$k]}  $root/$k" | sha256sum -c --quiet - || die "$k does not match the signed Packages file"
      ;;
    fedora)
      # An unsigned rpm still reports "digests OK", so require the signature.
      rpmkeys --dbpath "$rpmdb" --checksig "$root/$k" 2>&1 | grep -q 'signatures OK' ||
        die "$k does not verify against the trusted keys"
      ;;
  esac
  check_package "$root/$k"
done


# 2. Add new builds; an already-published file name wins over the new build.
declare -A built_names
new=()
shopt -s nullglob
for file in "$pkgdir"/*; do
  check_package "$file"
  read -r name _ < <(pkg_meta "$family" "$file")
  if [[ -n ${withdrawn[${file##*/}]:-} ]]; then
    log "not adding withdrawn ${file##*/}"
    matched[${file##*/}]=1
    continue
  fi
  built_names[$name]=1
  dest=$(pkg_dest "$file")
  if [[ -e $root/$dest ]]; then
    log "keeping published $dest (published files are immutable)"
    continue
  fi
  mkdir -p "$root/$(dirname "$dest")"
  cp "$file" "$root/$dest"
  new+=("$root/$dest")
  log "new: $dest"
done
[[ ${#built_names[@]} -gt 0 ]] || die "no packages in $pkgdir"

for f in "${!withdrawn[@]}"; do
  # Each target's job sees only its own files, so this is a warning.
  [[ -n ${matched[$f]:-} ]] || log "warning: withdraw: $f is not in $target's repository (typo, or another target?)"
done

# 3. Prune: drop packages without a recipe for this target, keep the newest
# $keep versions. A package this run did not build keeps its published files.
declare -A recipes
while read -r name; do recipes[$name]=1; done < <(packages_for)
declare -A versions
while IFS= read -r -d '' file; do
  read -r name ver < <(pkg_meta "$family" "$file")
  if [[ -z ${recipes[$name]:-} ]]; then
    log "dropping $file: $name has no recipe any more"
    rm -f "$file" "$file.sig"
    continue
  fi
  versions[$name]+="$ver"$'\t'"$file"$'\n'
done < <(find "$root" -type f \( -name '*.pkg.tar.zst' -o -name '*.deb' -o -name '*.rpm' \) -print0)

for name in "${!versions[@]}"; do
  # Selection sort, newest first, with the distribution's version comparison.
  mapfile -t rows < <(printf '%s' "${versions[$name]}")
  sorted=()
  while [[ ${#rows[@]} -gt 0 ]]; do
    best=0
    for i in "${!rows[@]}"; do
      vergt "$family" "${rows[$i]%%$'\t'*}" "${rows[$best]%%$'\t'*}" && best=$i
    done
    sorted+=("${rows[$best]}")
    unset 'rows[best]'
    rows=("${rows[@]}")
  done
  for row in "${sorted[@]:keep}"; do
    file=${row#*$'\t'}
    log "pruning old ${file#"$root"/}"
    rm -f "$file" "$file.sig"
  done
done

# 4. Sign new packages (all of them for a key rotation) and write the indices.
if [[ ${DEPOT_RESIGN:-} == 1 ]]; then
  mapfile -t new < <(find "$root" -type f \( -name '*.pkg.tar.zst' -o -name '*.rpm' \))
  log "re-signing ${#new[@]} packages"
fi
for file in "${new[@]}"; do
  [[ -e $file ]] || continue # pruned
  "$DEPOT_ROOT/scripts/repo.sh" sign "$target" "$file"
done
"$DEPOT_ROOT/scripts/repo.sh" index "$target" "$root"
cp "$DEPOT_ROOT/keys/depot.asc" "$root/depot.asc"

# 5. Upload what changed: packages first, then indices, then delete objects
# that are no longer in the tree.
content_type() {
  case $1 in
    *.asc | */Release | */InRelease | */Packages) echo text/plain ;;
    *.xml) echo application/xml ;;
    *.gz) echo application/gzip ;;
    *.zst) echo application/zstd ;;
    *.deb) echo application/vnd.debian.binary-package ;;
    *.rpm) echo application/x-rpm ;;
    *) echo application/octet-stream ;;
  esac
}
is_index() {
  case $1 in
    */depot.db* | */depot.files* | */dists/* | */repodata/*) return 0 ;;
  esac
  return 1
}
# R2 reports the MD5 of a single-part upload as its etag, so an unchanged
# file is skipped. If that ever changes, every file is uploaded again.
upload() {
  local k=$1 sum
  sum=$(md5sum "$root/$k" | cut -d' ' -f1)
  [[ ${remote[$k]:-} == "$sum" ]] && return 0
  log "upload $k"
  curl -fsS --retry 3 -X PUT -H @"$auth" -H "Content-Type: $(content_type "$k")" \
    --data-binary @"$root/$k" "$DEPOT_URL/$k" >/dev/null
}

declare -A local_keys
mapfile -t keys < <(cd "$root" && find . -type f | sed 's|^\./||' | sort)
for k in "${keys[@]}"; do local_keys[$k]=1; done
# The files a client reads first go up last, each next to its signature,
# so a client mid-update sees a consistent set for as short a time as can be.
is_entry() {
  case $1 in
    */depot.db* | */depot.files* | */dists/*/Release | */dists/*/Release.gpg | */dists/*/InRelease | */repomd.xml*) return 0 ;;
  esac
  return 1
}
for k in "${keys[@]}"; do is_index "$k" || upload "$k"; done
for k in "${keys[@]}"; do is_index "$k" && ! is_entry "$k" && upload "$k"; done
for k in "${keys[@]}"; do
  is_entry "$k" || continue
  case $k in *.sig | *.asc | */Release.gpg | */InRelease) continue ;; esac
  upload "$k"
  for sig in "$k.sig" "$k.asc"; do [[ -n ${local_keys[$sig]:-} ]] && upload "$sig"; done
  if [[ $k == */Release ]]; then upload "${k%/Release}/Release.gpg"; upload "${k%/Release}/InRelease"; fi
done
for k in "${!remote[@]}"; do
  [[ -n ${local_keys[$k]:-} ]] && continue
  log "delete $k"
  curl -fsS --retry 3 -X DELETE -H @"$auth" "$DEPOT_URL/$k" >/dev/null
done
log "published $target"
