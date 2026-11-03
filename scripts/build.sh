#!/usr/bin/env bash
# build.sh <target> <outdir> [package...]
# build.sh --prepare <target>
#
# Build the named packages, or every package that has a recipe for <target>,
# inside a throwaway container of that distribution running as root (CI's
# `container:` job, or `podman run`). It first upgrades the container, so
# packages build and link against the distribution as it is today. Upstream
# build code runs here: never give this step a secret. CI builds one package
# per job, so one package's build code never sees another's output.
#
# --prepare only upgrades the container and installs the build tools, which
# test-check-package.sh needs to craft its test packages.
source "$(dirname "$0")/lib.sh"

prepare_only=0
if [[ ${1:-} == --prepare ]]; then
  prepare_only=1
  shift
  [[ $# -eq 1 ]] || die "usage: build.sh --prepare <target>"
  set -- "$1" "$(mktemp -d)"
fi
[[ $# -ge 2 ]] || die "usage: build.sh <target> <outdir> [package...]"
target=$1
target_info "$target"
mkdir -p "$2"
out=$(cd "$2" && pwd)
shift 2
work=$(mktemp -d)

prepare_arch() {
  pacman -Syu --noconfirm --needed base-devel git
  # Upstream build code runs as builder, which has no sudo: root installs
  # the dependencies first.
  id builder &>/dev/null || useradd -m builder
  chown builder "$out"
  chmod 755 "$work"
}

prepare_debian() {
  export DEBIAN_FRONTEND=noninteractive
  # Backports, for build tools newer than the release ships (golang-1.26-go).
  # A built package may not need them at run time: install-test.sh installs
  # into a plain container without backports, so a runtime dependency on one
  # fails the test.
  printf 'Types: deb\nURIs: http://deb.debian.org/debian\nSuites: %s-backports\nComponents: main\nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg\n' \
    "$codename" >/etc/apt/sources.list.d/backports.sources
  apt-get update -q
  apt-get -qy dist-upgrade
  apt-get -qy install --no-install-recommends build-essential devscripts equivs curl ca-certificates libarchive-tools
}

prepare_fedora() {
  dnf -y upgrade
  dnf -y install rpm-build rpmdevtools dnf-plugins-core curl
}

build_arch() {
  local dir=$work/$1
  cp -r "$DEPOT_ROOT/packages/$1/arch" "$dir"
  chown -R builder "$dir"
  mapfile -t deps < <(cd "$dir" && runuser -u builder -- makepkg --printsrcinfo |
    awk -F' = ' '$1 ~ /^\t(make|check)?depends$/ {print $2}')
  [[ ${#deps[@]} -eq 0 ]] || pacman -S --noconfirm --needed --asdeps "${deps[@]}"
  (cd "$dir" && runuser -u builder -- env PKGDEST="$out" makepkg --noconfirm --cleanbuild)
}

build_debian() {
  local tarball src
  package_env "$1"
  tarball=$(fetch_source "$1" "$work")
  src=$work/$1-$pkg_version
  mkdir -p "$src"
  # A Go module zip nests the tree under <module>@<version>/, so its
  # package.env sets source_strip to that depth. GNU tar cannot read zips.
  case $tarball in
    *.zip) bsdtar -xf "$tarball" -C "$src" --strip-components="$pkg_source_strip" ;;
    *) tar -xf "$tarball" -C "$src" --strip-components="$pkg_source_strip" ;;
  esac
  cp -r "$DEPOT_ROOT/packages/$1/debian" "$src/debian"
  (
    cd "$src"
    mk-build-deps --install --remove --tool 'apt-get -qy --no-install-recommends' debian/control
    dpkg-buildpackage -b -us -uc
  )
  find "$work" -maxdepth 1 -name '*.deb' -exec mv -t "$out" {} +
}

build_fedora() {
  local top=$work/rpmbuild spec
  mkdir -p "$top/SOURCES"
  fetch_source "$1" "$top/SOURCES" >/dev/null
  spec=$DEPOT_ROOT/packages/$1/rpm/$1.spec
  dnf -y builddep "$spec"
  rpmbuild -bb --define "_topdir $top" "$spec"
  find "$top/RPMS" -name '*.rpm' -exec mv -t "$out" {} +
}

"prepare_$family"
[[ $prepare_only -eq 0 ]] || { log "prepared $target"; exit 0; }
mapfile -t known < <(packages_for)
if [[ $# -gt 0 ]]; then
  for name in "$@"; do
    [[ " ${known[*]} " == *" $name "* ]] || die "$name has no recipe for $target"
  done
  names=("$@")
else
  names=("${known[@]}")
fi
for name in "${names[@]}"; do
  log "building $name for $target"
  "build_$family" "$name"
done

for file in "$out"/*; do
  if is_debug_package "$file"; then rm -f "$file"; fi
done
log "built for $target:"
ls -l "$out" >&2
