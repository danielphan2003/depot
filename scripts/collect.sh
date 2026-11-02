#!/usr/bin/env bash
# collect.sh <target> <artifacts> <outdir>
#
# Gather one target's packages from the per-package build jobs. Each job
# uploads its output as <artifacts>/built-<target>-<package>/. A job may
# contribute only packages of its own name: otherwise one package's build
# code could ship a file under another package's recipe, which check_package
# would accept, since it only checks that some recipe has that name.
source "$(dirname "$0")/lib.sh"

[[ $# -eq 3 ]] || die "usage: collect.sh <target> <artifacts> <outdir>"
target=$1
target_info "$target"
mkdir -p "$3"
out=$(cd "$3" && pwd)

mapfile -t names < <(packages_for)
shopt -s nullglob
for name in "${names[@]}"; do
  dir=$2/built-$target-$name
  [[ -d $dir ]] || die "no build output for $name on $target"
  files=("$dir"/*)
  [[ ${#files[@]} -gt 0 ]] || die "the $name job built nothing for $target"
  for file in "${files[@]}"; do
    [[ -f $file && ! -L $file ]] || die "${file##*/} from the $name job is not a regular file"
    read -r got _ < <(pkg_meta "$family" "$file")
    [[ $got == "$name" ]] || die "the $name job produced ${file##*/}, a package named '$got'"
    [[ ! -e $out/${file##*/} ]] || die "two jobs produced ${file##*/}"
    cp "$file" "$out/"
  done
done
for dir in "$2"/built-"$target"-*; do
  [[ " ${names[*]} " == *" ${dir##*/built-"$target"-} "* ]] || die "unexpected build output ${dir##*/}"
done
log "collected for $target:"
ls -l "$out" >&2
