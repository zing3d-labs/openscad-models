#!/usr/bin/env bash
# Check out the submodules of a checkout, one level deep.
#
# Done here rather than through actions/checkout's `submodules:` option, for
# two reasons that outlive the bug that first forced it:
#
#   - This workflow checks out the merge base as well as the pull request head,
#     and the merge base can be any commit in the repository's history. Until
#     recently QuackWorks carried a gitlink it did not declare, which made
#     actions/checkout fail at any `submodules:` setting — it follows up with
#     `git submodule foreach --recursive` to persist credentials. That is fixed
#     upstream now, but a checkout of an older merge base still hits it.
#   - None of the submodules here declare submodules of their own, so recursing
#     would only cost time.
#
# Usage: init-submodules.sh [checkout-directory]
set -euo pipefail

git -C "${1:-.}" submodule update --init
git -C "${1:-.}" submodule status
