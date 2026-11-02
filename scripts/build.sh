#!/usr/bin/env bash
# build.sh <target> <outdir>
#
# Build every package that has a recipe for <target>, inside a throwaway
# container of that distribution running as root (CI's `container:` job, or
# `podman run`). It first upgrades the container, so packages build and link
# against the distribution as it is today. Upstream build code runs here: never
# give this step a secret.
source "$(dirname "$0")/lib.sh"

[[ $# -eq 2 ]] || die "usage: build.sh <target> <outdir>"
target=$1
target_info "$target"
mkdir -p "$2"
out=$(cd "$2" && pwd)
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
  apt-get update -q
  apt-get -qy dist-upgrade
  apt-get -qy install --no-install-recommends build-essential devscripts equivs curl ca-certificates
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
  tar -xf "$tarball" -C "$src" --strip-components=1
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
mapfile -t names < <(packages_for)
for name in "${names[@]}"; do
  log "building $name for $target"
  "build_$family" "$name"
done

for file in "$out"/*; do
  if is_debug_package "$file"; then rm -f "$file"; fi
done
log "built for $target:"
ls -l "$out" >&2
