#!/usr/bin/env bash
# Install the pinned OpenSCAD snapshot and export $OPENSCAD for later steps.
#
# The AppImage is extracted rather than mounted: GitHub-hosted runners have no
# FUSE, and extraction avoids needing it.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$here/../openscad-pin.env"

destination="${1:-$RUNNER_TEMP/openscad}"
mkdir -p "$destination"
cd "$destination"

file="OpenSCAD-${OPENSCAD_SNAPSHOT}-x86_64.AppImage"
url="https://files.openscad.org/snapshots/${file}"

if ! curl -fsSL --retry 3 --retry-delay 5 -o "$file" "$url"; then
  echo "::error::Could not download $url" >&2
  echo "Snapshots are removed from files.openscad.org after a while. Pick a" >&2
  echo "current one and update .github/openscad-pin.env." >&2
  exit 1
fi

echo "${OPENSCAD_SHA256}  ${file}" | sha256sum -c -
chmod +x "$file"
"./$file" --appimage-extract >/dev/null

binary="$destination/squashfs-root/AppRun"
echo "OPENSCAD=$binary" >>"$GITHUB_ENV"
"$binary" --version
