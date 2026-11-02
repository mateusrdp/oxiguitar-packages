#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Makes two small test packages (a made-up plugin, x86_64 and aarch64) with
# OxiGuitar's own packaging scripts, so the build of the site and its install
# test don't depend on any release existing.
#
# Usage: scripts/make-test-packages.sh OXIGUITAR-SCRIPTS-DIR OUT-DIR
#   OXIGUITAR-SCRIPTS-DIR  scripts/plugin-package of a checkout of
#                          mateusrdp/oxiguitar
set -euo pipefail
tools="$(cd "${1:?usage: make-test-packages.sh OXIGUITAR-SCRIPTS-DIR OUT-DIR}" && pwd)"
out="${2:?}"
mkdir -p "$out/deb" "$out/rpm"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
head -c 4096 /dev/urandom > "$work/test.oxp"
export PLUGIN_DESCRIPTION="A made-up plugin that tests this repository."
for arch in x86_64 aarch64; do
    "$tools/deb.sh" test 0.0.1 "$arch" "$out/deb" "$work/test.oxp" > /dev/null
done
# rpmbuild builds for the machine's own processor only.
"$tools/rpm.sh" test 0.0.1 "$(uname -m)" "$out/rpm" "$work/test.oxp" > /dev/null
ls "$out/deb" "$out/rpm"
