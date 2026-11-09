#!/usr/bin/env bash
# install-test.sh <target> <base-url> <public-key> [package...]
#
# Run in a fresh container of <target>'s distribution, as root. Upgrades it,
# adds the depot repository at <base-url> the way a machine would (key
# trusted, signatures required), installs the named packages, or every
# package that has a recipe for <target>, runs each package's test.sh, and
# fails if any installed ELF file has a missing shared library. CI runs it
# against the throwaway test repository on every build, naming the packages
# that run built, and against the published repository after publishing and
# daily (canary.yml), which catches a distribution library bump that broke a
# published binary.
#
# DEPOT_INSTALL_ONLY=1 installs the named packages that <base-url> has and
# tests nothing. CI's test job uses it to install the target's other packages
# from the live repository first, so a file one of this run's packages shares
# with them fails the install from the test repository that follows. It can
# run twice in one container: the second run points the depot repository at
# its own <base-url>.
source "$(dirname "$0")/lib.sh"

[[ $# -ge 3 ]] || die "usage: install-test.sh <target> <base-url> <public-key> [package...]"
target_info "$1"
base=$2
key=$(cd "$(dirname "$3")" && pwd)/$(basename "$3")
mapfile -t names < <(packages_for)
if [[ $# -gt 3 ]]; then
  for name in "${@:4}"; do
    [[ " ${names[*]} " == *" $name "* ]] || die "$name has no recipe for $1"
  done
  names=("${@:4}")
fi
[[ ${#names[@]} -gt 0 ]] || { log "no packages for $1"; exit 0; }

# only_available: with DEPOT_INSTALL_ONLY, drop the names the repository does
# not have (a package whose first publish has not run yet). None at all means
# the repository could not be read: a new target builds everything, so it
# never gets here. A built package that depends on a skipped one would fail
# the second pass; no depot package depends on another today.
only_available() {
  [[ ${DEPOT_INSTALL_ONLY:-} == 1 ]] || return 0
  local name kept=()
  for name in "${names[@]}"; do
    if available "$name"; then kept+=("$name"); else log "$base has no $name; not installing it"; fi
  done
  [[ ${#kept[@]} -gt 0 ]] || die "none of ${names[*]} are at $base; is it reachable?"
  names=("${kept[@]}")
}

case $family in
  arch)
    pacman -Syu --noconfirm
    # Container images ship no local master key; --init only creates one
    # when it is missing, as on a real machine.
    pacman-key --init
    pacman-key --add "$key"
    pacman-key --lsign-key "$(key_fingerprint "$key")"
    # [depot] is the last section, from an earlier run of this script.
    sed -i '/^\[depot\]$/,$d' /etc/pacman.conf
    cat >>/etc/pacman.conf <<CONF

[depot]
SigLevel = Required DatabaseRequired
Server = $base/arch/\$arch
CONF
    # A cached database from an earlier run's server would be kept if it is
    # newer than this server's, and then fail this server's signature.
    rm -f /var/lib/pacman/sync/depot.*
    pacman -Sy --noconfirm
    available() { pacman -Si "depot/$1" &>/dev/null; }
    only_available
    # --ask 4 accepts removing a conflicting package, as a machine does when
    # a depot package replaces one (run0-sudo-shim replaces sudo; only
    # relations that packages/<name>/allow grants get published).
    pacman -S --noconfirm --ask 4 "${names[@]/#/depot/}"
    files() { pacman -Qlq "$1"; }
    ;;
  debian)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -q
    apt-get -qy dist-upgrade
    apt-get -qy install --no-install-recommends ca-certificates
    install -Dm644 "$key" /etc/apt/keyrings/depot.asc
    # Machines pin depot below Debian (factory's add-depot.sh: depot may add
    # packages, never replace Debian's). Pin by the index's Origin, so the
    # local test repository gets the same rule as the live one; a package
    # that shares a name with a Debian package then fails here, not later.
    cat >/etc/apt/preferences.d/depot.pref <<CONF
Package: *
Pin: release o=depot
Pin-Priority: 100
CONF
    cat >/etc/apt/sources.list.d/depot.sources <<CONF
Types: deb
URIs: $base/debian
Suites: $codename
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/depot.asc
CONF
    # The depot source alone, with --error-on=any: a depot index that cannot
    # be fetched fails here, not as packages that seem to be missing, and a
    # Debian mirror hiccup does not.
    apt-get update -q --error-on=any -o Dir::Etc::SourceList=sources.list.d/depot.sources \
      -o Dir::Etc::SourceParts=- -o APT::Get::List-Cleanup=0
    available() { apt-cache madison "$1" | grep -qF " $base/debian "; }
    only_available
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
    # Fails when the repository cannot be read, and imports its key (-y).
    dnf -y makecache --repo depot
    available() { [[ -n $(dnf -y -q repoquery --repo depot "$1") ]]; }
    only_available
    dnf -y install "${names[@]}"
    files() { rpm -ql "$1"; }
    ;;
esac

if [[ ${DEPOT_INSTALL_ONLY:-} == 1 ]]; then
  log "installed from $base: ${names[*]}"
  exit 0
fi

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
