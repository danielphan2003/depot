# Shared helpers for depot's scripts. Source it; do not run it.
# shellcheck shell=bash
# Variables set here are read by the scripts that source this file, and the
# single-quoted ${...} are dpkg-deb formats, not shell expansions.
# shellcheck disable=SC2034,SC2016
set -euo pipefail

DEPOT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DEPOT_URL=${DEPOT_URL:-https://pkgs.c-137.me}
readonly DEPOT_ROOT DEPOT_URL

log() { printf '==> %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# The distributions depot builds for. Adding one means a case below, a row in
# the workflow matrices, and a line in the README's target table.
targets() { echo arch debian-trixie fedora-44; }

# target_info <target> sets:
#   family    arch | debian | fedora
#   recipe    the recipe directory inside packages/<name>/
#   prefixes  bucket prefixes this target owns (publish.sh replaces them)
#   repo_dir  where the packages go, relative to the bucket root
#   image     the container image that builds for it (matrix.sh)
target_info() {
  case $1 in
    arch)
      family=arch recipe=arch image=docker.io/library/archlinux:base-devel
      repo_dir=arch/x86_64
      prefixes=(arch/x86_64/)
      ;;
    debian-trixie)
      family=debian recipe=debian codename=trixie image=docker.io/library/debian:trixie
      repo_dir=debian/pool/trixie/main
      prefixes=(debian/dists/trixie/ debian/pool/trixie/)
      ;;
    fedora-44)
      family=fedora recipe=rpm image=registry.fedoraproject.org/fedora:44
      repo_dir=fedora/44/x86_64
      prefixes=(fedora/44/x86_64/)
      ;;
    *) die "unknown target: $1 (known: $(targets))" ;;
  esac
}

# Packages with a recipe for the current target (call target_info first).
packages_for() {
  local dir
  for dir in "$DEPOT_ROOT"/packages/*/; do
    [[ -e $dir$recipe ]] && basename "$dir"
  done
  return 0
}

# package_env <name>: load packages/<name>/package.env into pkg_* variables
# without executing it (lint.sh also rejects anything but key=value lines).
package_env() {
  local file=$DEPOT_ROOT/packages/$1/package.env key value
  [[ -f $file ]] || die "missing $file"
  pkg_version='' pkg_source_url='' pkg_sha256='' pkg_upstream='' pkg_source_strip=1
  while IFS='=' read -r key value; do
    case $key in
      '' | '#'*) ;;
      version) pkg_version=$value ;;
      source_url) pkg_source_url=$value ;;
      sha256) pkg_sha256=$value ;;
      upstream) pkg_upstream=$value ;;
      source_strip) pkg_source_strip=$value ;;
      *) die "$file: unknown key $key" ;;
    esac
  done <"$file"
  [[ -n $pkg_version && -n $pkg_source_url && -n $pkg_sha256 ]] ||
    die "$file: version, source_url and sha256 are required"
}

# fetch_source <name> <destdir>: download the upstream tarball named in
# package.env into destdir and check its sha256. Prints the file path.
fetch_source() {
  package_env "$1"
  local out="$2/${pkg_source_url##*/}"
  curl -fsSL --retry 3 -o "$out" "$pkg_source_url"
  echo "$pkg_sha256  $out" | sha256sum -c --quiet - >&2 ||
    die "$1: sha256 mismatch for $pkg_source_url"
  echo "$out"
}

# Package files a build produced, without debug packages (depot does not
# publish them).
is_debug_package() {
  case ${1##*/} in
    *-debug-*.pkg.tar.* | *.ddeb | *-dbgsym_* | *-debuginfo-* | *-debugsource-*) return 0 ;;
  esac
  return 1
}

# pkg_meta <family> <file>: print "<name> <version>" of a package file.
pkg_meta() {
  case $1 in
    arch)
      bsdtar -xOqf "$2" .PKGINFO |
        awk -F' = ' '$1=="pkgname"{n=$2} $1=="pkgver"{v=$2} END{print n, v}'
      ;;
    debian) dpkg-deb --showformat='${Package} ${Version}\n' --show "$2" ;;
    fedora) rpm -qp --nosignature --qf '%{NAME} %{EPOCHNUM}:%{VERSION}-%{RELEASE}\n' "$2" ;;
  esac
}

# vergt <family> <a> <b>: succeed when version a is newer than b, using the
# distribution's own comparison.
vergt() {
  case $1 in
    arch) [[ $(vercmp "$2" "$3") -gt 0 ]] ;;
    debian) dpkg --compare-versions "$2" gt "$3" ;;
    fedora)
      local rc=0
      rpmdev-vercmp "$2" "$3" >/dev/null || rc=$?
      [[ $rc -eq 11 ]]
      ;;
  esac
}

# Fingerprint of the key in an armored public key file, which must hold
# exactly one primary key: apt and rpm trust every key in such a file.
key_fingerprint() {
  local colons
  colons=$(gpg --batch --show-keys --with-colons "$1")
  [[ $(grep -c '^pub:' <<<"$colons") -eq 1 ]] || die "$1 must hold exactly one key"
  awk -F: '$1=="fpr"{print $10; exit}' <<<"$colons"
}

# pkg_dest <file>: where a package file goes, relative to the bucket root
# (call target_info first).
pkg_dest() {
  local base=${1##*/} src
  case $family in
    arch | fedora) echo "$repo_dir/$base" ;;
    debian)
      src=$(dpkg-deb --showformat='${source:Package}' --show "$1")
      echo "$repo_dir/${src:0:1}/$src/$base"
      ;;
  esac
}

# check_package <file>: refuse a package that could do anything on a machine
# beyond installing its own plain files. Upstream build code runs as root on
# Debian and Fedora and could write any package into the build output, and
# publish signs what it is given, so this checks the built packages, not the
# recipes. The package must:
#   - be named after a package directory with a recipe for this target;
#   - declare no replaces, provides (beyond its own name), conflicts,
#     obsoletes, breaks, pre-depends or Essential;
#   - carry no install scripts, triggers, file capabilities or extended
#     attributes;
#   - contain only regular files and directories, with plain names, in
#     usr/bin, usr/lib{,64}/<name>, usr/share/doc/<name>,
#     usr/share/licenses/<name> and usr/share/man, plus the exact paths its
#     recipe's packages/<name>/allow lists, all owned by root and none of
#     them setuid, setgid, group- or world-writable.
# Anything else needs a deliberate change here, or an allow entry, with
# Daniel's approval.
check_package() {
  local file=$1 base=${1##*/} name ver names listing owners bad line key
  case $family in
    arch)
      # repo-add declares a shell variable per .PKGINFO key, so validate the
      # format before anything parses it, reading it the way repo-add does.
      local -A seen=()
      while IFS= read -r line || [[ -n $line ]]; do
        [[ ${line:0:1} == '#' ]] && continue
        # A blank value would end a section in repo-add's database entry and
        # let the next value start a new one (%REPLACES%), so values must
        # be non-blank and may not start with whitespace, % or = (repo-add
        # splits on = too).
        [[ $line =~ ^([a-z0-9]+)\ =\ ([^[:cntrl:][:space:]%=][^[:cntrl:]]*)$ ]] || die "$base: malformed .PKGINFO line: $line"
        key=${BASH_REMATCH[1]}
        case $key in
          pkgname | pkgbase | pkgver | pkgdesc | url | builddate | packager | size | arch | license | xdata | depend | optdepend | makedepend | checkdepend) ;;
          *) die "$base: .PKGINFO key '$key' is not allowed" ;;
        esac
        seen[$key]=$((${seen[$key]:-0} + 1))
        line=${BASH_REMATCH[2]}
        case $key in
          pkgname | pkgbase) [[ $line =~ ^[a-z0-9][a-z0-9.+_-]*$ ]] ;;
          pkgver) [[ $line =~ ^([0-9]+:)?[A-Za-z0-9._+~]+-[0-9]+(\.[0-9]+)?$ ]] ;;
          arch) [[ $line =~ ^(x86_64|any)$ ]] ;;
          builddate | size) [[ $line =~ ^[0-9]+$ ]] ;;
          depend | makedepend | checkdepend) [[ $line =~ ^[A-Za-z0-9@._+:-]+((<|<=|=|>=|>)[A-Za-z0-9._+:~-]+)?$ ]] ;;
          optdepend) [[ $line =~ ^[A-Za-z0-9@._+-]+(: [^%]*)?$ ]] ;;
          *) true ;;
        esac || die "$base: .PKGINFO $key has a malformed value: $line"
      done < <(bsdtar -xOqf "$file" .PKGINFO)
      for key in pkgname pkgbase pkgver arch; do
        [[ ${seen[$key]:-0} -eq 1 ]] || die "$base: .PKGINFO needs exactly one $key"
      done
      names=$(bsdtar -tf "$file")
      # pacman reads every .PKGINFO member, repo-add and this check only the
      # first, so a second one could smuggle in relations. Exactly one.
      [[ $(grep -cxF .PKGINFO <<<"$names") -eq 1 ]] || die "$base: needs exactly one .PKGINFO member"
      bad=$(sed -E 's|^\.?/||; s|/$||' <<<"$names" | sort | uniq -d)
      [[ -z $bad ]] || die "$base: duplicate members: $bad"
      names=$(grep -vxE '\.(PKGINFO|BUILDINFO|MTREE)' <<<"$names" || true)
      listing=$(bsdtar -tvf "$file" | awk '$NF !~ /^\.(PKGINFO|BUILDINFO|MTREE)$/')
      # pacman applies the numeric ids and ignores the names.
      owners=$(bsdtar --numeric-owner -tvf "$file" | awk '$3 != "0" || $4 != "0"')
      # Extended attributes, such as file capabilities, travel in pax headers.
      # Capture rather than test a pipeline status: with pipefail, grep -q
      # exiting early makes zstd die of SIGPIPE and the test read as false.
      # A sanity check that this is a zstd-compressed tar. libarchive (and
      # so pacman) reads nested compression and other formats too, which
      # this cannot fully rule out; the re-pax scan below, which reads the
      # entries the way libarchive does, is the control that matters.
      zstd -tq "$file" || die "$base: does not decompress"
      [[ $(zstd -dcq "$file" | head -c 262 | tail -c 5 | tr -d '\0' || true) == ustar ]] || die "$base: is not a zstd-compressed tar"
      # Read the entries as libarchive reads them, rewritten as pax, and list
      # their pax headers with GNU tar (-P: names as they are, so it prints no
      # notice about them), which reads headers only. A grep of
      # the whole stream also matched file contents: flyctl, a Go binary with
      # archive/tar compiled in, contains "SCHILY.xattr.". An extended
      # attribute, ACL or SELinux label, or any keyword GNU tar does not know
      # (libarchive's own LIBARCHIVE.xattr.*), refuses the package.
      tar --version 2>/dev/null | grep -q '^tar (GNU tar)' || die "GNU tar is needed to check $base"
      local pax
      pax=$(bsdtar -cf - --format=pax @"$file" |
        LC_ALL=C tar -P --xattrs --xattrs-include='*' --acls --selinux -tvvf - 2>&1 || echo 'tar: listing failed')
      bad=$(grep -E '^  [axs]: |^(bsd)?tar: ' <<<"$pax" | sort -u | head -5 || true)
      [[ -z $bad ]] || die "$base: carries extended attributes: $bad"
      ;;
    debian)
      # Query fields by name: dpkg matches field names case-insensitively.
      for key in Replaces Breaks Pre-Depends Conflicts Provides; do
        [[ -z $(dpkg-deb -f "$file" "$key") ]] || die "$base: declares $key"
      done
      # dpkg reports a missing Essential field as "no".
      [[ $(dpkg-deb -f "$file" Essential) == no ]] || die "$base: declares Essential"
      bad=$(dpkg-deb --ctrl-tarfile "$file" | tar -t | sed 's|^\./||' |
        grep -vxE '|control|md5sums' || true)
      [[ -z $bad ]] || die "$base: has control files beyond metadata: $bad"
      names=$(dpkg-deb --fsys-tarfile "$file" | tar -t)
      # dpkg resolves names first, then falls back to the ids: check both.
      owners=$(
        dpkg-deb --fsys-tarfile "$file" | tar --numeric-owner -tv | awk '$2 != "0/0"'
        dpkg-deb -c "$file" | awk '$2 != "root/root"'
      )
      # dpkg ignores tar extended attributes today; refuse them anyway.
      bad=$(dpkg-deb --fsys-tarfile "$file" | grep -aoE '(SCHILY|LIBARCHIVE)\.xattr\.[!-~]+' | sort -u | head -5 || true)
      [[ -z $bad ]] || die "$base: carries extended attributes: $bad"
      listing=$(dpkg-deb -c "$file")
      ;;
    fedora)
      for key in obsoletes conflicts supplements enhances; do
        [[ -z $(rpm -qp --nosignature "--$key" "$file") ]] || die "$base: declares $key"
      done
      read -r name _ < <(pkg_meta fedora "$file")
      local evr epoch
      evr=$(rpm -qp --nosignature --qf '%{VERSION}-%{RELEASE}' "$file")
      epoch=$(rpm -qp --nosignature --qf '%{EPOCHNUM}' "$file")
      bad=$(rpm -qp --nosignature --provides "$file" | awk -v n="$name" -v v="$evr" -v e="$epoch:$evr" \
        '!(($1 == n || $1 == n "(x86-64)") && $2 == "=" && ($3 == v || $3 == e) && NF == 3)')
      [[ -z $bad ]] || die "$base: provides more than itself: $bad"
      [[ -z $(rpm -qp --nosignature --scripts --triggers --filetriggers "$file") ]] ||
        die "$base: has scriptlets or triggers"
      [[ -z $(rpm -qp --nosignature --filecaps "$file" | awk -F'\t' '$2 != ""') ]] ||
        die "$base: declares file capabilities"
      bad=$(rpm -qp --nosignature --qf '[%{FILELINKTOS}\n]' "$file" | grep -v '^$' || true)
      [[ -z $bad ]] || die "$base: contains symlinks"
      names=$(rpm -qp --nosignature --qf '[%{FILENAMES}\n]' "$file")
      owners=$(rpm -qp --nosignature --qf '[%{FILEUSERNAME}:%{FILEGROUPNAME} %{FILENAMES}\n]' "$file" | awk '$1 != "root:root"')
      listing=$(rpm -qp --nosignature --qf '[%{FILEMODES:perms} %{FILENAMES}\n]' "$file")
      ;;
  esac

  read -r name ver < <(pkg_meta "$family" "$file")
  [[ $name =~ ^[a-z0-9][a-z0-9.+_-]*$ && -f $DEPOT_ROOT/packages/$name/package.env && -e $DEPOT_ROOT/packages/$name/$recipe ]] ||
    die "$base: package '$name' has no recipe for $family; refusing it"

  # Plain names only, each once, so no listing below can be misread.
  bad=$(grep -E '[[:space:][:cntrl:]\\]' <<<"$names" || true)
  [[ -z $bad ]] || die "$base: file names with whitespace or control characters"
  bad=$(sed -E 's|^\.?/||; s|/$||' <<<"$names" | sort | uniq -d)
  [[ -z $bad ]] || die "$base: duplicate members: $bad"
  bad=$(sed -E 's|^\.?/||' <<<"$names" | grep -E '(^|/)\.{1,2}(/|$)' || true)
  [[ -z $bad ]] || die "$base: paths with . or .. components: $bad"

  # Only regular files and directories, none setuid or setgid.
  bad=$(awk '$1 !~ /^[-d]/ || $1 ~ /^.{5}w/ || $1 ~ /^.{8}w/' <<<"$listing")
  [[ -z $bad ]] || die "$base: contains links, special, group- or world-writable files: $bad"
  [[ -z $owners ]] || die "$base: files not owned by root: $owners"
  bad=$(awk '$1 ~ /^.(..[sS]|.....[sS])/' <<<"$listing")
  [[ -z $bad ]] || die "$base: setuid or setgid files: $bad"
  bad=$(grep -E ' link to ' <<<"$listing" || true)
  [[ -z $bad ]] || die "$base: contains hard links: $bad"

  # Every path must be under an allowed directory (or be one of its parents).
  local n=${name//./\\.}
  n=${n//+/\\+}
  local paths
  paths=$(sed -E 's|^\.?/||; s|/$||' <<<"$names")
  bad=$(grep -vxE "|usr|usr/bin|usr/lib|usr/share|usr/share/(doc|licenses|man)|usr/bin/[^/]+|usr/lib/$n(/.+)?|usr/lib64|usr/lib64/$n(/.+)?|usr/share/(doc|licenses)/$n(/.+)?|usr/share/man/([a-z][a-z](_[A-Z][A-Z])?|[a-z][a-z](_[A-Z][A-Z])?/man[0-9n]|man[0-9n])(/[^/]+)?" <<<"$paths" || true)
  # Beyond that, only what packages/<name>/allow names (allowed_paths).
  if [[ -n $bad ]]; then
    local extra
    extra=$(allowed_paths "$name")
    [[ -z $extra ]] || bad=$(grep -vxE "$extra" <<<"$bad" || true)
    # A parent directory of an allowed entry is allowed too. Each entry under
    # it is checked on its own, and every directory is root's and not
    # writable (checked above).
    local p left=''
    while IFS= read -r p; do
      [[ -n $p ]] || continue
      awk -v p="$p/" 'index($0, p) == 1 { found = 1; exit } END { exit !found }' <<<"$paths" ||
        left+="$p"$'\n'
    done <<<"$bad"
    bad=${left%$'\n'}
  fi
  [[ -z $bad ]] || die "$base: installs outside usr/bin, usr/lib{,64}/$name, usr/share/{doc,licenses}/$name, usr/share/man and packages/$name/allow: $bad"
}

# allowed_paths <name>: the extra paths packages/<name>/allow grants, as one
# extended regular expression of whole paths (empty if none). The file is a
# reviewed part of the recipe; nothing in a built package can change it. Each
# entry is a line `path <ERE>`, matched against the whole path without a
# leading slash; comments say why. Adding an entry needs Daniel's approval.
allowed_paths() {
  local file=$DEPOT_ROOT/packages/$1/allow kind pattern rest out=''
  [[ -f $file ]] || return 0
  while read -r kind pattern rest; do
    case $kind in
      '' | '#'*) continue ;;
      path)
        [[ -n $pattern && -z $rest && $pattern != */ && $pattern =~ ^usr/ ]] ||
          die "$file: malformed entry: path $pattern $rest"
        out+="${out:+|}($pattern)"
        ;;
      *) die "$file: unknown entry '$kind'" ;;
    esac
  done <"$file"
  printf '%s' "$out"
}

# Tools the signing and index steps need, installed into a fresh container.
install_repo_tools() {
  case $family in
    arch) pacman -Syu --noconfirm --needed gnupg jq curl libarchive ;;
    debian)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -q
      apt-get -qy install --no-install-recommends apt-utils gnupg gpgv jq curl ca-certificates dpkg-dev
      ;;
    fedora) dnf -y install createrepo_c rpm-sign rpmdevtools gnupg2 jq curl ;;
  esac
}
