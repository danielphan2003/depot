#!/usr/bin/env bash
# test-check-package.sh <target> <pkgdir>
#
# Regression tests for check_package, the control publish.sh relies on to
# keep a hostile build from shipping more than plain programs in usr/bin.
# It builds crafted packages named like a real one (so they pass the name
# check and reach the deeper ones), expects each to be refused for the
# stated reason, and expects every real package in <pkgdir> to be accepted.
# Every case here is a bypass a review found; add one with each new rule.
# Runs as root in the target's build container, after build.sh.
source "$(dirname "$0")/lib.sh"

[[ $# -eq 2 ]] || die "usage: test-check-package.sh <target> <pkgdir>"
target_info "$1"
pkgdir=$(cd "$2" && pwd)
mapfile -t names < <(packages_for)
[[ ${#names[@]} -gt 0 ]] || { log "no packages for $1"; exit 0; }
name=${names[0]}
work=$(mktemp -d)
failures=0

# expect_refused <file> <pattern>: check_package must die with a message
# matching the pattern.
expect_refused() {
  local out
  if [[ ! -s $1 ]]; then
    log "FAIL: the fixture for '$2' was not built"
    failures=$((failures + 1))
    return
  fi
  if out=$( (check_package "$1") 2>&1); then
    log "FAIL: accepted ${1##*/} (expected: $2)"
    failures=$((failures + 1))
  elif ! grep -qE "$2" <<<"$out"; then
    log "FAIL: ${1##*/} refused for the wrong reason: $out (expected: $2)"
    failures=$((failures + 1))
  else
    log "ok: refused ${1##*/}: ${out#error: }"
  fi
}

expect_accepted() {
  local out
  if out=$( (check_package "$1") 2>&1); then
    log "ok: accepted ${1##*/}"
  else
    log "FAIL: refused real package ${1##*/}: $out"
    failures=$((failures + 1))
  fi
}

# --- arch -------------------------------------------------------------------

pkginfo() {
  cat <<EOF
pkgname = $name
pkgbase = $name
pkgver = 9.9.9-1
pkgdesc = crafted test package
url = https://example.invalid
builddate = 1
packager = depot test
size = 1
arch = x86_64
license = MIT
EOF
}

# arch_pkg <case> <extra .PKGINFO lines> [setup command]: a package with
# usr/bin/<name>, after running the setup command inside its tree.
arch_pkg() {
  local dir=$work/$1 out=$work/$1.pkg.tar.zst
  mkdir -p "$dir/usr/bin"
  printf '#!/bin/sh\n' >"$dir/usr/bin/$name"
  chmod 755 "$dir/usr/bin/$name"
  { pkginfo; printf '%s' "$2"; } >"$dir/.PKGINFO"
  (cd "$dir" && eval "${3:-true}")
  (cd "$dir" && bsdtar --xattrs -cf - .PKGINFO usr | zstd -qf -o "$out")
  echo "$out"
}

test_arch() {
  local f
  # shellcheck disable=SC2016 # the $(...) is the payload, not an expansion
  expect_refused "$(arch_pkg inject 'evil[$(touch /tmp/depot-pwned)] = 1'$'\n')" 'malformed .PKGINFO line'
  expect_refused "$(arch_pkg unspaced $'replaces=sudo\n')" 'malformed .PKGINFO line'
  expect_refused "$(arch_pkg replaces $'replaces = sudo\n')" "key 'replaces' is not allowed"
  expect_refused "$(arch_pkg rename $'pkgname = sudo\n')" 'exactly one pkgname'
  expect_refused "$(arch_pkg badname "" "mkdir -p usr/lib/$name; printf x > 'usr/lib/$name/z .Xevil'")" 'whitespace'
  expect_refused "$(arch_pkg hook "" 'mkdir -p usr/share/libalpm/hooks; printf x > usr/share/libalpm/hooks/x.hook')" 'installs outside'
  expect_refused "$(arch_pkg setuid "" "chmod 4755 usr/bin/$name")" 'setuid'
  expect_refused "$(arch_pkg worldwritable "" "mkdir -p usr/lib/$name; chmod 777 usr/lib/$name")" 'world-writable'
  expect_refused "$(arch_pkg symlink "" "ln -s /etc/shadow usr/bin/$name-link")" 'links'

  # A capability in a pax header, followed by enough data that grep -q
  # would exit before zstd finished writing.
  f=$(arch_pkg caps "" "setcap cap_setuid=ep usr/bin/$name; mkdir -p usr/lib/$name; head -c 67108864 /dev/zero > usr/lib/$name/pad")
  # The capability first, the padding after it.
  (cd "$work/caps" && bsdtar --xattrs -cf - .PKGINFO "usr/bin/$name" "usr/lib/$name/pad" | zstd -qf -o "$f")
  expect_refused "$f" 'extended attributes'
  # The same words inside a file are not a header: flyctl, a Go binary with
  # archive/tar compiled in, contains them.
  expect_accepted "$(arch_pkg paxtext "" "mkdir -p usr/lib/$name; printf '30 SCHILY.xattr.security.capability=x\nLIBARCHIVE.xattr.user.x=eA\n' > usr/lib/$name/data")"

  # A second .PKGINFO member, which pacman reads and repo-add does not.
  local dir=$work/dup
  mkdir -p "$dir/usr/bin"
  printf '#!/bin/sh\n' >"$dir/usr/bin/$name"
  pkginfo >"$dir/.PKGINFO"
  printf 'pkgname = %s\nreplaces = sudo\n' "$name" >"$dir/second"
  (cd "$dir" && tar -cf ../dup.tar .PKGINFO usr && tar -rf ../dup.tar --transform='s|^second$|.PKGINFO|' second)
  zstd -qf "$work/dup.tar" -o "$work/dup.pkg.tar.zst"
  expect_refused "$work/dup.pkg.tar.zst" 'exactly one .PKGINFO'

  # An install script.
  f=$(arch_pkg install "" 'printf "post_install() { :; }\n" > .INSTALL')
  (cd "$work/install" && bsdtar -cf - .PKGINFO .INSTALL usr | zstd -qf -o "$f")
  expect_refused "$f" 'not allowed|outside|INSTALL'

  # An empty list value ends a section in repo-add's database entry, so
  # the next value could start a %REPLACES% section.
  expect_refused "$(arch_pkg eqvalue $'license = =\nlicense = =%REPLACES%\n')" 'malformed .PKGINFO line'
  expect_refused "$(arch_pkg dbinject $'depend = glibc\ndepend =\ndepend = %REPLACES%\ndepend = sudo\n')" 'malformed .PKGINFO line'

  # libarchive, and so pacman, reads nested compression and other formats;
  # the format sanity check refuses these plain cases.
  f=$(arch_pkg nested "")
  (cd "$work/nested" && bsdtar -cf - .PKGINFO usr | zstd -q | zstd -qf -o "$f")
  expect_refused "$f" 'not a zstd-compressed tar'
  f=$(arch_pkg zip "")
  (cd "$work/zip" && bsdtar --format zip -cf - .PKGINFO usr | zstd -qf -o "$f")
  expect_refused "$f" 'not a zstd-compressed tar'

  # Owners: pacman applies the numeric ids, even when the names say root.
  f=$(arch_pkg owner "")
  (cd "$work/owner" && bsdtar --uid 65534 --uname root --gid 65534 --gname root -cf - .PKGINFO usr | zstd -qf -o "$f")
  expect_refused "$f" 'not owned by root'
  expect_refused "$(arch_pkg groupwritable "" "mkdir -p usr/lib/$name; chmod 775 usr/lib/$name")" 'group- or world-writable'

  # A member path with a .. component.
  dir=$work/dots
  mkdir -p "$dir/usr/bin"
  printf '#!/bin/sh\n' >"$dir/usr/bin/$name"
  pkginfo >"$dir/.PKGINFO"
  (cd "$dir" && bsdtar -s ",^usr/bin/$name\$,usr/lib/$name/../evil," -cf - .PKGINFO "usr/bin/$name" | zstd -qf -o "$work/dots.pkg.tar.zst")
  expect_refused "$work/dots.pkg.tar.zst" '\.\. components'
}

# --- debian -----------------------------------------------------------------

# deb_pkg <case> <extra control lines> [setup command]
deb_pkg() {
  local dir=$work/$1
  mkdir -p "$dir/DEBIAN" "$dir/usr/bin"
  printf '#!/bin/sh\n' >"$dir/usr/bin/$name"
  chmod 755 "$dir/usr/bin/$name"
  printf 'Package: %s\nVersion: 9.9.9-1\nArchitecture: amd64\nMaintainer: depot test <test@example.invalid>\nDescription: crafted test package\n%s' \
    "$name" "$2" >"$dir/DEBIAN/control"
  (cd "$dir" && eval "${3:-true}")
  dpkg-deb --root-owner-group --build "$dir" "$work/$1.deb" >/dev/null
  echo "$work/$1.deb"
}

test_debian() {
  expect_refused "$(deb_pkg essential $'Essential: yes\n')" 'Essential'
  expect_refused "$(deb_pkg lowercase $'replaces: sudo\n')" 'Replaces'
  expect_refused "$(deb_pkg conflicts $'Conflicts: sudo\n')" 'Conflicts'
  expect_refused "$(deb_pkg provides $'Provides: sudo\n')" 'Provides'
  expect_refused "$(deb_pkg postinst "" 'printf "#!/bin/sh\n" > DEBIAN/postinst; chmod 755 DEBIAN/postinst')" 'control files'
  expect_refused "$(deb_pkg unit "" 'mkdir -p lib/systemd/system; printf x > lib/systemd/system/x.service')" 'installs outside'
  expect_refused "$(deb_pkg etc "" 'mkdir -p etc; printf x > etc/x')" 'installs outside'
  expect_refused "$(deb_pkg setuid "" "chmod 4755 usr/bin/$name")" 'setuid'
  expect_refused "$(deb_pkg symlink "" "ln -s /etc/shadow usr/bin/$name-link")" 'links'

  # Files owned by another user (dpkg-deb keeps owners without
  # --root-owner-group).
  local o=$work/owner-deb
  mkdir -p "$o/DEBIAN" "$o/usr/bin"
  printf '#!/bin/sh\n' >"$o/usr/bin/$name"
  printf 'Package: %s\nVersion: 9.9.9-1\nArchitecture: amd64\nMaintainer: t <t@example.invalid>\nDescription: t\n' "$name" >"$o/DEBIAN/control"
  chown -R 65534:65534 "$o/usr"
  dpkg-deb --build "$o" "$work/owner.deb" >/dev/null
  expect_refused "$work/owner.deb" 'not owned by root'

  # Extended attributes in data.tar: rebuild the archive with a pax xattr
  # record on every member (GNU tar's --pax-option adds it as given).
  local f dir=$work/xattr
  f=$(deb_pkg xattr "")
  mkdir -p "$dir/ar" && cd "$dir/ar"
  ar x "$f"
  rm -f data.tar.*
  tar --format=pax --pax-option='SCHILY.xattr.security.capability=x' -C "$work/xattr" \
    --exclude=./DEBIAN --exclude=./ar -cf data.tar .
  rm -f "$f"
  ar rc "$f" debian-binary control.tar.* data.tar
  cd - >/dev/null
  expect_refused "$f" 'extended attributes'
}

# --- fedora -----------------------------------------------------------------

# rpm_pkg <case> <extra preamble> <extra %install> <extra %files> [extra sections]
rpm_pkg() {
  local top=$work/rpm-$1
  mkdir -p "$top/SPECS"
  cat >"$top/SPECS/t.spec" <<EOF
%global debug_package %{nil}
Name: $name
Version: 9.9.9
Release: 1
Summary: crafted test package
License: MIT
$2
%description
crafted test package
%install
mkdir -p %{buildroot}/usr/bin
printf '#!/bin/sh\n' > %{buildroot}/usr/bin/$name
chmod 755 %{buildroot}/usr/bin/$name
$3
%files
/usr/bin/$name
$4
${5:-}
EOF
  rpmbuild -bb --quiet --define "_topdir $top" "$top/SPECS/t.spec" >/dev/null 2>&1 || die "rpmbuild failed for case $1"
  find "$top/RPMS" -name '*.rpm' -print -quit
}

test_fedora() {
  expect_refused "$(rpm_pkg obsoletes 'Obsoletes: sudo' '' '')" 'obsoletes'
  expect_refused "$(rpm_pkg provides 'Provides: sudo' '' '')" 'provides more than itself'
  expect_refused "$(rpm_pkg fakeversion "Provides: $name = 99.0" '' '')" 'provides more than itself'
  expect_refused "$(rpm_pkg post '' '' '' $'%post\ntrue')" 'scriptlets'
  expect_refused "$(rpm_pkg caps '' "cp %{buildroot}/usr/bin/$name %{buildroot}/usr/bin/$name-caps" "%caps(cap_setuid=ep) /usr/bin/$name-caps" '')" 'capabilities'
  expect_refused "$(rpm_pkg symlink '' "ln -s /etc/shadow %{buildroot}/usr/bin/$name-link" "/usr/bin/$name-link" '')" 'symlinks'
  expect_refused "$(rpm_pkg etc '' 'mkdir -p %{buildroot}/etc; printf x > %{buildroot}/etc/x' '/etc/x' '')" 'installs outside'
  expect_refused "$(rpm_pkg owner '' "cp %{buildroot}/usr/bin/$name %{buildroot}/usr/bin/$name-nobody" "%attr(-,nobody,nobody) /usr/bin/$name-nobody" '')" 'not owned by root'
  expect_refused "$(rpm_pkg setuid '' "cp %{buildroot}/usr/bin/$name %{buildroot}/usr/bin/$name-suid" "%attr(4755,root,root) /usr/bin/$name-suid" '')" 'setuid'
}

"test_$family"
for file in "$pkgdir"/*; do expect_accepted "$file"; done
[[ $failures -eq 0 ]] || die "$failures check_package test(s) failed"
log "check_package tests passed for $1"
