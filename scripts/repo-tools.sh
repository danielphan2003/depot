#!/usr/bin/env bash
# repo-tools.sh <target>: install the tools that sign, index, check and
# verify packages. The publish workflow runs it in a step of its own, so the
# distribution's install scripts never run with the signing key or the upload
# token in the environment.
source "$(dirname "$0")/lib.sh"
[[ $# -eq 1 ]] || die "usage: repo-tools.sh <target>"
target_info "$1"
install_repo_tools
