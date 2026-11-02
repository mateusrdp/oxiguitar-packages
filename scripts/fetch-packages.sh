#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Downloads the .deb and .rpm files of the latest published release of every
# repository in repositories.txt into OUT-DIR/deb and OUT-DIR/rpm, checking
# each against the release's SHA256SUMS. A repository without a published
# release is skipped with a notice; a file whose sum is missing or wrong stops
# the run. Needs gh (GH_TOKEN) and sha256sum.
#
# Usage: scripts/fetch-packages.sh OUT-DIR [REPOSITORIES-FILE]
set -euo pipefail
trap 'echo "::error::fetch-packages.sh line $LINENO: $BASH_COMMAND"' ERR

out="${1:?usage: fetch-packages.sh OUT-DIR [REPOSITORIES-FILE]}"
list="${2:-$(dirname "$0")/../repositories.txt}"
mkdir -p "$out/deb" "$out/rpm"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

while read -r repo; do
    [[ -z "$repo" || "$repo" == \#* ]] && continue
    tag="$(gh api "repos/$repo/releases" --jq '[.[] | select(.draft | not)] | first | .tag_name // empty')"
    if [[ -z "$tag" ]]; then
        echo "::notice::$repo has no published release yet: skipped."
        continue
    fi
    dir="$tmp/${repo//\//_}"
    mkdir -p "$dir"
    gh release download "$tag" --repo "$repo" --dir "$dir" \
        --pattern '*.deb' --pattern '*.rpm' --pattern SHA256SUMS
    [[ -f "$dir/SHA256SUMS" ]] || { echo "::error::$repo $tag has no SHA256SUMS"; exit 1; }
    count=0
    for f in "$dir"/*.deb "$dir"/*.rpm; do
        [[ -f "$f" ]] || continue
        name="$(basename "$f")"
        want="$(awk -v n="$name" '$2 == n || $2 == "*" n { print $1 }' "$dir/SHA256SUMS")"
        have="$(sha256sum "$f" | cut -d' ' -f1)"
        [[ -n "$want" && "$want" == "$have" ]] || { echo "::error::$repo $tag: $name does not match SHA256SUMS"; exit 1; }
        case "$name" in
            *.deb) cp "$f" "$out/deb/" ;;
            *.rpm) cp "$f" "$out/rpm/" ;;
        esac
        count=$((count + 1))
    done
    echo "$repo $tag: $count package file(s)"
done < "$list"
