#!/usr/bin/env bash
# lint.sh: check that every package's recipes agree with its package.env,
# that each package is watched by nvchecker, and that the scripts pass
# ShellCheck when it is installed. CI runs it first.
source "$(dirname "$0")/lib.sh"

errors=0
err() { printf 'lint: %s\n' "$*" >&2; errors=$((errors + 1)); }

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
  [[ $pkg_source_strip =~ ^[1-9]$ ]] || err "$name: source_strip must be a number from 1 to 9"
  [[ $pkg_source_url == *"$pkg_version"* ]] || err "$name: source_url does not contain version $pkg_version"
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
