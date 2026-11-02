#!/usr/bin/env bash
# open-bump-prs.sh <updates-file>
#
# For each "<package> <current> <latest>" line from nvcheck.sh, run bump.sh,
# push a branch bump/<package>-<latest> and open a pull request, unless that
# branch already exists. The lines come from a job that ran third-party code,
# so each one is checked against the repository before use. Needs git push
# access, gh and GH_TOKEN.
source "$(dirname "$0")/lib.sh"

[[ $# -eq 1 ]] || die "usage: open-bump-prs.sh <updates-file>"
while read -r name cur latest extra; do
  [[ -z $name ]] && continue
  [[ -z ${extra:-} && $name =~ ^[a-z0-9][a-z0-9._+-]*$ && -f $DEPOT_ROOT/packages/$name/package.env ]] ||
    die "bad update line: $name $cur $latest $extra"
  [[ $latest =~ ^[0-9A-Za-z.+~_-]+$ ]] || die "$name: suspicious version $latest"
  package_env "$name"
  [[ $cur == "$pkg_version" ]] || die "$name: nvchecker saw $cur, the repository has $pkg_version"

  branch=bump/$name-$latest
  if git ls-remote --exit-code --heads origin "$branch" >/dev/null; then
    # A run that pushed the branch but failed before opening the PR would
    # otherwise block this update for good.
    if [[ -n $(gh pr list --state all --head "$branch" --json number --jq '.[].number') ]]; then
      log "$branch already has a PR; skipping"
      continue
    fi
    log "$branch exists without a PR; opening one"
  else
    git switch --quiet -c "$branch" origin/main
    "$DEPOT_ROOT/scripts/bump.sh" "$name" "$latest"
    git add -A "packages/$name"
    git commit --quiet -m "feat($name): update to $latest"
    git push --quiet origin "$branch"
    git switch --quiet main
  fi
  body=$(
    cat <<BODY
nvchecker found $name $latest upstream (depot has $cur). This PR only moves the recipes to the new tag and records its sha256; **nobody has reviewed the upstream change yet**, and lint fails until packages/$name/AUDIT.md has a \`## $latest-1\` entry.

Before merging, an agent audits the change with the checklist in README.md ("Update a package"), starting from the upstream diff:
${pkg_upstream:-upstream}/compare/v$cur...v$latest
BODY
  )
  gh pr create --base main --head "$branch" --title "feat($name): update to $latest" --body "$body"
  # Pull requests opened with GITHUB_TOKEN do not trigger pull_request
  # workflows, so start the build on the branch explicitly.
  gh workflow run build.yml --ref "$branch"
done <"$1"
