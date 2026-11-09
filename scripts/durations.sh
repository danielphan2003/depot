#!/usr/bin/env bash
# durations.sh <owner/repo>: print "<target> <package> <seconds>" for each
# build job in the last five passing runs of build.yml and the last weekly
# run, which builds everything, the newest time for each. matrix.sh uses it ($DEPOT_DURATIONS) to start the longest builds
# first. Needs gh with a token that can read Actions. Best effort: a failed
# request leaves lines out, never fails the run.
source "$(dirname "$0")/lib.sh"
[[ $# -eq 1 ]] || die "usage: durations.sh <owner/repo>"

runs=$(gh api "repos/$1/actions/workflows/build.yml/runs?status=success&per_page=5" \
  --jq '.workflow_runs[].id') || exit 0
# Last, so newer times win. Only its passing jobs count (the filter below).
runs+=" $(gh api "repos/$1/actions/workflows/build.yml/runs?event=schedule&status=completed&per_page=1" \
  --jq '.workflow_runs[].id' || true)"
# The $ names below are jq variables, not shell expansions.
# shellcheck disable=SC2016
filter='.jobs[]
  | select(.conclusion == "success" and (.name | startswith("build (")))
  | (.name | capture("^build \\((?<t>[^,]+), (?<p>[^)]+)\\)$")) as $n
  | "\($n.t) \($n.p) \((.completed_at | fromdate) - (.started_at | fromdate))"'
for run in $runs; do
  gh api "repos/$1/actions/runs/$run/jobs?per_page=100" --jq "$filter" || true
done | awk '!seen[$1 " " $2]++'
