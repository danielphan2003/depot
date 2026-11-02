#!/usr/bin/env bash
# install-test.sh <target> <base-url> <public-key>
#
# Run in a fresh container of <target>'s distribution, as root. Upgrades it,
# adds the depot repository at <base-url> the way a machine would (key
# trusted, signatures required), installs every package that has a recipe for
# <target>, runs each package's test.sh, and fails if any installed ELF file
# has a missing shared library. CI runs it against the throwaway test
# repository on every build, and against the published repository after
# publishing and daily (canary.yml), which catches a distribution library
# bump that broke a published binary.
source "$(dirname "$0")/lib.sh"

[[ $# -eq 3 ]] || die "usage: install-test.sh <target> <base-url> <public-key>"
target_info "$1"
base=$2
key=$(cd "$(dirname "$3")" && pwd)/$(basename "$3")
mapfile -t names < <(packages_for)
[[ ${#names[@]} -gt 0 ]] || { log "no packages for $1"; exit 0; }

case $family in
  arch)
    pacman -Syu --noconfirm
    # Container images ship no local master key; --init only creates one
    # when it is missing, as on a real machine.
    pacman-key --init
    pacman-key --add "$key"
    pacman-key --lsign-key "$(key_fingerprint "$key")"
    cat >>/etc/pacman.conf <<CONF

[depot]
SigLevel = Required DatabaseRequired
Server = $base/arch/\$arch
CONF
    pacman -Sy --noconfirm
    pacman -S --noconfirm "${names[@]/#/depot/}"
    files() { pacman -Qlq "$1"; }
    ;;
  debian)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -q
    apt-get -qy dist-upgrade
    apt-get -qy install --no-install-recommends ca-certificates
    install -Dm644 "$key" /etc/apt/keyrings/depot.asc
    if [[ $base == http*://* ]]; then
      host=${base#*://}
      host=${host%%/*}
      cat >/etc/apt/preferences.d/depot.pref <<CONF
Package: *
Pin: origin $host
Pin-Priority: 100
CONF
    fi
    cat >/etc/apt/sources.list.d/depot.sources <<CONF
Types: deb
URIs: $base/debian
Suites: $codename
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/depot.asc
CONF
    apt-get update -q
    apt-get -qy install --no-install-recommends "${names[@]}"
    files() { dpkg -L "$1"; }
    ;;
  fedora)
    dnf -y upgrade
    install -Dm644 "$key" /etc/pki/rpm-gpg/RPM-GPG-KEY-depot
    cat >/etc/yum.repos.d/depot.repo <<CONF
[depot]
name=depot
baseurl=$base/fedora/\$releasever/\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-depot
includepkgs=${names[*]}
CONF
    dnf -y install "${names[@]}"
    files() { rpm -ql "$1"; }
    ;;
esac

failed=0
for name in "${names[@]}"; do
  package_env "$name"
  log "testing $name $pkg_version"
  DEPOT_VERSION=$pkg_version "$DEPOT_ROOT/packages/$name/test.sh" || { log "FAIL: $name test.sh"; failed=1; }
  while IFS= read -r file; do
    [[ -f $file && ! -L $file ]] || continue
    [[ $(head -c4 "$file" | od -An -c | tr -d ' ') == 177ELF ]] || continue
    if missing=$(ldd "$file" 2>&1 | grep 'not found'); then
      log "FAIL: $file has missing libraries:"
      echo "$missing" >&2
      failed=1
    fi
  done < <(files "$name")
done
[[ $failed -eq 0 ]] || die "install test failed for $1"
log "install test passed for $1"
