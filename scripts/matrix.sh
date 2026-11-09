#!/usr/bin/env bash
# matrix.sh [<base>]: print the jobs build.yml runs, as one JSON object:
#   build    one entry per package and target: {target, image, package}.
#            One package's build code never sees another package's output.
#   repo     one entry per target that builds anything:
#            {target, image, packages}, packages space-separated.
#   publish  the same targets: {target, image}, in the target's first run image.
#   test     one entry per target that builds anything and image that
#            installs it: {target, image, packages}.
#
# With <base>, a commit, only what the change from <base> to HEAD can affect
# builds: a file in a recipe directory (packages/<name>/arch/, debian/ or
# rpm/, lib.sh's target_info) builds <name> for the targets that use it, any
# other file of packages/<name>/ builds <name> for every target it has a
# recipe for, and docs and files that no build reads build nothing. Removing
# a recipe builds its whole target, so publish.sh drops the package from that
# repository in the same run. Any other file builds everything, and so does a
# <base> that cannot be diffed. Without <base>, everything builds.
#
# GitHub starts only so many jobs at once, so the build entries come longest
# first, by the seconds in $DEPOT_DURATIONS (lines "<target> <package>
# <seconds>", from earlier runs). A build with no recorded time goes first.
source "$(dirname "$0")/lib.sh"

[[ $# -le 1 ]] || die "usage: matrix.sh [<base>]"

all=1
declare -A want=() whole=() by_recipe=()
for t in $(targets); do
  target_info "$t"
  by_recipe[$recipe]+="$t "
done
if [[ $# -eq 1 ]]; then
  # --no-renames: a rename must also show the path it removed.
  if mb=$(git -C "$DEPOT_ROOT" merge-base "$1" HEAD 2>/dev/null) &&
    files=$(git -C "$DEPOT_ROOT" diff --no-renames --name-only "$mb" HEAD 2>/dev/null); then
    all=0
  else
    log "cannot diff $1...HEAD; building everything"
  fi
fi

if [[ $all -eq 0 ]]; then
  while IFS= read -r f; do
    case $f in
      '') ;;
      # Docs, and files that only lint, the bump and canary workflows or the
      # infrastructure read. lint runs on every change anyway.
      docs/* | *.md | infra/* | ci/* | nvchecker.toml | .gitignore | .shellcheckrc) ;;
      .github/workflows/bump.yml | .github/workflows/canary.yml) ;;
      scripts/lint.sh | scripts/bump.sh | scripts/bump-release.sh | scripts/nvcheck.sh) ;;
      scripts/open-bump-prs.sh | scripts/report.sh) ;;
      packages/*/*)
        rest=${f#packages/}
        name=${rest%%/*}
        sub=${rest#*/}
        if [[ $sub == */* && -n ${by_recipe[${sub%%/*}]:-} ]]; then
          for t in ${by_recipe[${sub%%/*}]}; do want["$t $name"]=1; done
        else
          for t in $(targets); do want["$t $name"]=1; done
        fi
        ;;
      *)
        log "$f can affect every build; building everything"
        all=1
        break
        ;;
    esac
  done <<<"$files"
fi

if [[ $all -eq 0 ]]; then
  for key in "${!want[@]}"; do
    t=${key%% *}
    name=${key#* }
    target_info "$t"
    if [[ ! -e $DEPOT_ROOT/packages/$name/$recipe ]] &&
      git -C "$DEPOT_ROOT" cat-file -e "$mb:packages/$name/$recipe" 2>/dev/null; then
      log "$name no longer has a recipe for $t; building all of $t"
      whole[$t]=1
    fi
  done
fi

declare -A seconds=()
if [[ -n ${DEPOT_DURATIONS:-} && -f $DEPOT_DURATIONS ]]; then
  while read -r t name secs; do
    [[ $secs =~ ^[0-9]+$ ]] && seconds["$t $name"]=$secs
  done <"$DEPOT_DURATIONS"
fi

for t in $(targets); do
  target_info "$t"
  pkgs=()
  while read -r name; do
    [[ $all -eq 1 || -n ${whole[$t]:-} || -n ${want["$t $name"]:-} ]] && pkgs+=("$name")
  done < <(packages_for)
  [[ ${#pkgs[@]} -gt 0 ]] || continue
  log "$t: ${pkgs[*]}"
  for name in "${pkgs[@]}"; do
    jq -cn --arg target "$t" --arg image "$image" --arg package "$name" \
      --argjson seconds "${seconds["$t $name"]:-1000000}" \
      '{job: "build", target: $target, image: $image, package: $package, seconds: $seconds}'
  done
  jq -cn --arg target "$t" --arg image "$image" --arg packages "${pkgs[*]}" \
    '{job: "repo", target: $target, image: $image, packages: $packages}'
  jq -cn --arg target "$t" --arg image "${run_images[0]}" \
    '{job: "publish", target: $target, image: $image}'
  for run_image in "${run_images[@]}"; do
    jq -cn --arg target "$t" --arg image "$run_image" --arg packages "${pkgs[*]}" \
      '{job: "test", target: $target, image: $image, packages: $packages}'
  done
done | jq -cs '{
  build: map(select(.job == "build")) | sort_by(-.seconds) | map(del(.job, .seconds)),
  repo: map(select(.job == "repo") | del(.job)),
  publish: map(select(.job == "publish") | del(.job)),
  test: map(select(.job == "test") | del(.job))
}'
