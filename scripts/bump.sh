#!/usr/bin/env bash
# bump.sh <package> <new-version>
#
# Point every recipe of <package> at a new upstream release: package.env,
# PKGBUILD, debian/changelog and the rpm spec, with the release reset to 1.
# It downloads the new tarball to record its sha256. It does not review
# anything: an agent audits the upstream diff before the PR is merged
# (README.md, "Updating a package").
source "$(dirname "$0")/lib.sh"

[[ $# -eq 2 ]] || die "usage: bump.sh <package> <new-version>"
name=$1 new=$2
dir=$DEPOT_ROOT/packages/$name
[[ $new =~ ^[0-9A-Za-z.+~_-]+$ ]] || die "suspicious version: $new"
package_env "$name"
old=$pkg_version
[[ $old != "$new" ]] || die "$name is already at $new"

# Replace the version only where it stands alone, so "2" never touches the
# "2" in "fido2".
old_re=${old//./\\.}
url=$(sed -E "s/(^|[^0-9A-Za-z.]v?)$old_re([^0-9A-Za-z.]|\.[^0-9]|$)/\1$new\2/g" <<<"$pkg_source_url")
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL --retry 3 -o "$tmp/src" "$url"
sha=$(sha256sum "$tmp/src" | cut -d' ' -f1)
log "$name $old -> $new: $url ($sha)"

sed -i -e "s|^version=.*|version=$new|" -e "s|^source_url=.*|source_url=$url|" \
  -e "s|^sha256=.*|sha256=$sha|" "$dir/package.env"

if [[ -f $dir/arch/PKGBUILD ]]; then
  sed -i -e "s|^pkgver=.*|pkgver=$new|" -e "s|^pkgrel=.*|pkgrel=1|" \
    -e "s|^sha256sums=('[0-9a-f]*'|sha256sums=('$sha'|" "$dir/arch/PKGBUILD"
fi

if [[ -f $dir/debian/changelog ]]; then
  {
    printf '%s (%s-1) unstable; urgency=medium\n\n  * Upstream release %s.\n\n -- depot <noreply@github.com>  %s\n\n' \
      "$name" "$new" "$new" "$(date -uR)"
    cat "$dir/debian/changelog"
  } >"$tmp/changelog"
  cp "$tmp/changelog" "$dir/debian/changelog"
fi

spec=$dir/rpm/$name.spec
if [[ -f $spec ]]; then
  entry="* $(LC_ALL=C date -u '+%a %b %d %Y') depot <noreply@github.com> - $new-1\n- Upstream release $new.\n"
  sed -i -e "s|^\(Version:[[:space:]]*\).*|\1$new|" \
    -e "s|^\(Release:[[:space:]]*\)[0-9]*|\11|" \
    -e "s|^%changelog\$|%changelog\n$entry|" "$spec"
fi
log "updated $name to $new; review the upstream changes before merging"
