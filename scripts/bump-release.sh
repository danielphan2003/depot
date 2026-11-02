#!/usr/bin/env bash
# bump-release.sh <package> [target...]
#
# Increment the package release (pkgrel, Debian revision, rpm Release) without
# changing the upstream version, so CI publishes a rebuild against the current
# distribution. Use it when the canary reports a broken library link, or when
# a published recipe changes. With no targets, bumps every recipe.
source "$(dirname "$0")/lib.sh"

[[ $# -ge 1 ]] || die "usage: bump-release.sh <package> [target...]"
name=$1
shift
dir=$DEPOT_ROOT/packages/$name
[[ -d $dir ]] || die "no package $name"
if [[ $# -eq 0 ]]; then read -ra all < <(targets) && set -- "${all[@]}"; fi
package_env "$name"

for target in "$@"; do
  target_info "$target"
  case $family in
    arch)
      pb=$dir/arch/PKGBUILD
      [[ -f $pb ]] || continue
      rel=$(sed -n 's/^pkgrel=//p' "$pb")
      sed -i "s/^pkgrel=.*/pkgrel=$((${rel%%.*} + 1))/" "$pb"
      log "$name: arch pkgrel $rel -> $((${rel%%.*} + 1))"
      ;;
    debian)
      cl=$dir/debian/changelog
      [[ -f $cl ]] || continue
      cur=$(sed -n '1s/^[^(]*(\([^)]*\)).*/\1/p' "$cl")
      next=${cur%-*}-$((${cur##*-} + 1))
      {
        printf '%s (%s) unstable; urgency=medium\n\n  * Rebuild for %s against current libraries.\n\n -- depot <noreply@github.com>  %s\n\n' \
          "$name" "$next" "$codename" "$(date -uR)"
        cat "$cl"
      } >"$cl.new"
      mv "$cl.new" "$cl"
      log "$name: debian $cur -> $next"
      ;;
    fedora)
      spec=$dir/rpm/$name.spec
      [[ -f $spec ]] || continue
      rel=$(sed -n 's/^Release:[[:space:]]*\([0-9]*\).*/\1/p' "$spec")
      entry="* $(LC_ALL=C date -u '+%a %b %d %Y') depot <noreply@github.com> - $pkg_version-$((rel + 1))\n- Rebuild against current libraries.\n"
      sed -i -e "s/^\(Release:[[:space:]]*\)[0-9]*/\1$((rel + 1))/" \
        -e "s|^%changelog\$|%changelog\n$entry|" "$spec"
      log "$name: rpm Release $rel -> $((rel + 1))"
      ;;
  esac
done
