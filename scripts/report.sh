#!/usr/bin/env bash
# report.sh open <title> <body>    open an issue, or comment on the open one
# report.sh close <title> <comment> close the open issue with that title
# Used by the scheduled workflows; needs gh and GH_TOKEN.
source "$(dirname "$0")/lib.sh"

[[ $# -eq 3 ]] || die "usage: report.sh open|close <title> <body>"
action=$1 title=$2 body=$3
number=$(gh issue list --state open --search "\"$title\" in:title" --json number,title |
  jq -r --arg t "$title" 'map(select(.title == $t))[0].number // empty')

case $action in
  open)
    if [[ -n $number ]]; then
      gh issue comment "$number" --body "$body"
    else
      gh issue create --title "$title" --body "$body"
    fi
    ;;
  close)
    [[ -z $number ]] || gh issue close "$number" --comment "$body"
    ;;
  *) die "usage: report.sh open|close <title> <body>" ;;
esac
