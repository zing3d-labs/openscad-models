#!/usr/bin/env bash
# Publish rendered comparison images to the `ci-renders` orphan branch and
# print the raw.githubusercontent base URL they can be linked from.
#
# GitHub strips data: URIs out of comment bodies and serves workflow artifacts
# as auth-gated zips, so an image can only appear inline in a PR comment if it
# is fetchable over plain HTTP. An orphan branch in this same repository is the
# established way to do that.
#
# The branch is rewritten as a single root commit on every push, so its history
# never grows and deleting a directory actually reclaims the space.
#
# Usage: publish-images.sh <images-dir> <pr-number>
#   <images-dir> holds one directory per part, named after the part.
set -euo pipefail

source_dir="$1"
pr_number="$2"
branch="${CI_RENDERS_BRANCH:-ci-renders}"
# Directories for pull requests untouched for this long are swept up. The
# comment for a merged PR keeps pointing at images that are gone; that is the
# accepted trade for not growing the branch without limit.
retention_days="${CI_RENDERS_RETENTION_DAYS:-90}"

: "${GITHUB_TOKEN:?GITHUB_TOKEN is required to push to $branch}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_RUN_ID:?GITHUB_RUN_ID is required}"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
remote="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}"

push_attempt() {
  rm -rf "$work/renders"
  if ! git clone --quiet --depth 1 --branch "$branch" "$remote" "$work/renders" 2>/dev/null; then
    git init --quiet "$work/renders"
    git -C "$work/renders" remote add origin "$remote"
    git -C "$work/renders" checkout --quiet --orphan "$branch"
  fi
  git -C "$work/renders" config user.name "github-actions[bot]"
  git -C "$work/renders" config user.email "41898282+github-actions[bot]@users.noreply.github.com"

  local target="$work/renders/pr-${pr_number}"
  # Everything this PR published before is unreferenced the moment the comment
  # is updated in place, so it goes rather than accumulating per push.
  rm -rf "$target"
  mkdir -p "$target/${GITHUB_RUN_ID}" || return 1
  cp -R "$source_dir"/. "$target/${GITHUB_RUN_ID}/" || return 1

  local now
  now="$(date -u +%s)"
  local manifest="$work/renders/manifest.json"
  [ -f "$manifest" ] || echo '{}' >"$manifest"
  python3 - "$manifest" "$pr_number" "$now" "$retention_days" "$work/renders" <<'PY'
import json, shutil, sys
from pathlib import Path

manifest_path, pr, now, retention_days, root = sys.argv[1:6]
now, retention_days = int(now), int(retention_days)
try:
    manifest = json.loads(Path(manifest_path).read_text())
except (ValueError, OSError):
    manifest = {}
manifest[str(pr)] = now
cutoff = now - retention_days * 86400
for key, stamp in list(manifest.items()):
    if int(stamp) < cutoff:
        shutil.rmtree(Path(root) / f"pr-{key}", ignore_errors=True)
        manifest.pop(key)
Path(manifest_path).write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
PY
  cat >"$work/renders/README.md" <<README
# ci-renders

Rendered comparison images published by \`.github/workflows/visual-regression.yml\`
so they can be shown inline in pull request comments.

Nothing here is source. The branch is rewritten as a single commit on every
run, and directories for pull requests untouched for ${retention_days} days are
removed.
README

  # A fresh root commit each time, so the branch is always exactly one commit.
  git -C "$work/renders" checkout --quiet --orphan publish
  git -C "$work/renders" add -A || return 1
  git -C "$work/renders" commit --quiet -m "Renders for #${pr_number} (run ${GITHUB_RUN_ID})" || return 1
  git -C "$work/renders" push --quiet --force "$remote" "HEAD:refs/heads/${branch}"
}

for attempt in 1 2 3 4 5; do
  if push_attempt; then
    echo "https://raw.githubusercontent.com/${GITHUB_REPOSITORY}/${branch}/pr-${pr_number}/${GITHUB_RUN_ID}"
    exit 0
  fi
  # Another job in this run may have force-pushed in between the clone and the
  # push. Start over from whatever is there now.
  echo "push attempt $attempt failed, retrying" >&2
  sleep $((attempt * 5))
done

echo "::error::Could not publish images to $branch after 5 attempts" >&2
exit 1
