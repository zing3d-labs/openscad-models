#!/usr/bin/env bash
# Post a comment on a pull request, replacing this workflow's previous one
# rather than stacking a new one on every push.
#
# Each body starts with a hidden marker naming the part it reports on, so a PR
# that touches two parts carries one current comment per part instead of a
# growing pile of stale ones.
#
# Usage: upsert-comment.sh <pr-number> <marker> <body-file>
set -euo pipefail

pr_number="$1"
marker="$2"
body_file="$3"

: "${GITHUB_TOKEN:?GITHUB_TOKEN is required to comment}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"

existing="$(
  gh api --paginate "repos/${GITHUB_REPOSITORY}/issues/${pr_number}/comments" \
    --jq ".[] | select(.body | contains(\"${marker}\")) | .id" | head -n 1
)"

if [ -n "$existing" ]; then
  gh api -X PATCH "repos/${GITHUB_REPOSITORY}/issues/comments/${existing}" -F "body=@${body_file}" >/dev/null
  echo "updated comment ${existing}"
else
  gh api -X POST "repos/${GITHUB_REPOSITORY}/issues/${pr_number}/comments" -F "body=@${body_file}" >/dev/null
  echo "created a new comment"
fi
