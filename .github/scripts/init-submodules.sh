#!/usr/bin/env bash
# Check out the submodules of a checkout, non-recursively.
#
# actions/checkout's own `submodules:` option cannot be used here. Even the
# non-recursive setting runs `git submodule foreach --recursive` afterwards to
# persist credentials, and that dies on QuackWorks: it carries a gitlink for
# MultiConnectOpenSCAD that its own .gitmodules never declares. Nothing in this
# repository depends on that nested repository, so one level is all we want.
#
# Usage: init-submodules.sh [checkout-directory]
set -euo pipefail

git -C "${1:-.}" submodule update --init
git -C "${1:-.}" submodule status
