#!/usr/bin/env bash
# lint.sh: check that every package's recipes agree with its package.env,
# that each package is watched by nvchecker, and that the scripts pass
# ShellCheck when it is installed. CI runs it first.
source "$(dirname "$0")/lib.sh"

errors=0
err() { printf 'lint: %s\n' "$*" >&2; errors=$((errors + 1)); }

# check_attestation <name>: package.env's attest= says source_url is
# upstream's release binary and names the GitHub attestation it carries.
# Check that attestation for the pinned file (call package_env first):
#   release           GitHub's immutable-release attestation: the file is the
#                     unchanged asset upstream published with that tag.
#   build:<workflow>  SLSA build provenance, signed by that workflow file in
#                     upstream's repository, run for that tag.
# Needs gh; CI has it, and a local run without it skips the check.
check_attestation() {
  local name=$1 repo tag file dir ok=0
  if [[ ! $pkg_source_url =~ ^https://github\.com/([^/]+/[^/]+)/releases/download/([^/]+)/([^/]+)$ ]]; then
    err "$name: attest= needs a GitHub release asset as source_url"
    return
  fi
  repo=${BASH_REMATCH[1]} tag=${BASH_REMATCH[2]} file=${BASH_REMATCH[3]}
  [[ $pkg_attest == release || $pkg_attest =~ ^build:\.github/workflows/[A-Za-z0-9_.-]+\.ya?ml$ ]] ||
    { err "$name: attest must be 'release' or 'build:.github/workflows/<file>'"; return; }
  if ! command -v gh >/dev/null; then
    if [[ -n ${CI:-} ]]; then err "$name: gh is needed to check its attestation"; else log "gh not installed; $name's attestation not checked"; fi
    return
  fi
  dir=$(mktemp -d)
  # fetch_source checks the pinned sha256, so the attestation is checked for
  # exactly the file the build packages.
  if (fetch_source "$name" "$dir" >/dev/null); then
    case $pkg_attest in
      release) gh release verify-asset "$tag" "$dir/$file" -R "$repo" >/dev/null && ok=1 ;;
      build:*)
        gh attestation verify "$dir/$file" --repo "$repo" --signer-workflow "$repo/${pkg_attest#build:}" \
          --source-ref "refs/tags/$tag" >/dev/null && ok=1
        ;;
    esac
  fi
  rm -rf "$dir"
  [[ $ok -eq 1 ]] || err "$name: $file does not carry a valid '$pkg_attest' attestation from $repo"
}

for dir in "$DEPOT_ROOT"/packages/*/; do
  name=$(basename "$dir")
  env=$dir/package.env
  if grep -vqE '^(#.*|[a-z0-9_]+=[^$`"'"'"' ]*|)$' "$env"; then
    err "$name: package.env may hold only key=value lines without quotes, spaces or \$"
    continue
  fi
  package_env "$name"
  [[ $pkg_sha256 =~ ^[0-9a-f]{64}$ ]] || err "$name: sha256 is not a sha256"
  [[ $pkg_source_url == https://* ]] || err "$name: source_url must be https"
  [[ $pkg_source_strip =~ ^[0-9]$ ]] || err "$name: source_strip must be a number from 0 to 9"
  [[ $pkg_source_url == *"$pkg_version"* ]] || err "$name: source_url does not contain version $pkg_version"
  [[ -z $pkg_attest ]] || check_attestation "$name"
  [[ -x $dir/test.sh ]] || err "$name: test.sh is missing or not executable"
  if [[ ! -f $dir/AUDIT.md ]]; then
    err "$name: AUDIT.md is missing"
  elif ! grep -q "^## ${pkg_version//./\\.}-" "$dir/AUDIT.md"; then
    err "$name: AUDIT.md has no '## $pkg_version-<release>' entry; audit the upstream change first"
  fi
  grep -q "^\[$name\]" "$DEPOT_ROOT/nvchecker.toml" || err "$name: no [$name] entry in nvchecker.toml"
  if [[ -f $dir/allow ]]; then
    (allowed_paths "$name" >/dev/null && allowed_relations "$name" >/dev/null) || err "$name: allow is malformed"
    grep -q "^- \*\*Allowed paths:\*\*" "$dir/AUDIT.md" ||
      err "$name: has an allow file, so AUDIT.md needs an '- **Allowed paths:**' item saying why"
  fi

  found=0
  if [[ -f $dir/arch/PKGBUILD ]]; then
    found=1
    pb=$dir/arch/PKGBUILD
    grep -qx "pkgname=$name" "$pb" || err "$name: PKGBUILD pkgname is not $name"
    grep -qx "pkgver=$pkg_version" "$pb" || err "$name: PKGBUILD pkgver is not $pkg_version"
    grep -q "^sha256sums=('$pkg_sha256'" "$pb" || err "$name: PKGBUILD sha256sums[0] is not package.env's sha256"
    grep -q '^install=' "$pb" && err "$name: PKGBUILD has an install script; depot recipes do not run scriptlets"
  fi
  if [[ -d $dir/debian ]]; then
    found=1
    top=$(head -1 "$dir/debian/changelog")
    [[ $top =~ ^$name\ \(([^\)]+)\) ]] || err "$name: debian/changelog does not start with $name (version)"
    debver=${BASH_REMATCH[1]:-}
    debver=${debver#*:}
    [[ ${debver%-*} == "$pkg_version" ]] || err "$name: debian/changelog version $debver is not $pkg_version-<rev>"
    for script in preinst postinst prerm postrm; do
      [[ -e $dir/debian/$script || -n $(compgen -G "$dir/debian/*.$script") ]] &&
        err "$name: debian/$script: depot recipes do not run maintainer scripts"
    done
  fi
  if [[ -d $dir/rpm ]]; then
    found=1
    spec=$dir/rpm/$name.spec
    if [[ ! -f $spec ]]; then
      err "$name: rpm/$name.spec is missing"
    else
      grep -qE "^Version:[[:space:]]+$pkg_version\$" "$spec" || err "$name: spec Version is not $pkg_version"
      grep -qE '^%(pre|post|preun|postun|pretrans|posttrans|triggerin|triggerun|filetriggerin)\b' "$spec" &&
        err "$name: spec has scriptlets; depot recipes do not run them"
    fi
  fi
  [[ $found -eq 1 ]] || err "$name: no recipe (arch/PKGBUILD, debian/ or rpm/)"
done

if command -v shellcheck >/dev/null; then
  shellcheck -x "$DEPOT_ROOT"/scripts/*.sh "$DEPOT_ROOT"/packages/*/test.sh || errors=$((errors + 1))
else
  log "shellcheck not installed; skipped"
fi

[[ $errors -eq 0 ]] || die "$errors lint error(s)"
log "lint passed"
