#!/usr/bin/env bash
# matrix.sh: print the build matrix as JSON, one entry per package and
# target: [{"target":"arch","image":"...","package":"..."}, ...]. build.yml
# runs one build job per entry, so one package's build code never sees
# another package's output.
source "$(dirname "$0")/lib.sh"

for t in $(targets); do
  target_info "$t"
  while read -r name; do
    jq -cn --arg target "$t" --arg image "$image" --arg package "$name" \
      '{target: $target, image: $image, package: $package}'
  done < <(packages_for)
done | jq -cs .
