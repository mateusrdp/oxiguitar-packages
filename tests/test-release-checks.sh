#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Tries the checks plugin-release.yml and plugin-publish.yml make before a
# release goes out, on made-up files: scripts/plugin-package/check-assets.sh
# (every file of a release there, and SHA256SUMS right about them) and
# check-glibc.sh (no ELF file needs a newer glibc than allowed). Needs no
# network. scripts/test-all.py runs it.
#
# Usage: tests/test-release-checks.sh
# Needs sha256sum, and objdump for check-glibc.sh (skipped without it).
set -euo pipefail
cd "$(dirname "$0")/.."
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail() { echo "FAILED: $*" >&2; exit 1; }
assets=scripts/plugin-package/check-assets.sh
glibc=scripts/plugin-package/check-glibc.sh

# A release of plugin "demo", version 1.2.0-rc.1, for the given systems.
release() {
    local dir="$1"
    shift
    rm -rf "$dir"
    mkdir -p "$dir"
    local v=1.2.0-rc.1 r=1.2.0~rc.1 f
    local files=()
    for s in "$@"; do
        case "$s" in
        linux) files+=("oxiguitar-demo-$v-linux-x86_64.zip" "oxiguitar-demo-$v-linux-aarch64.zip"
            "oxiguitar-demo_${v}_amd64.deb" "oxiguitar-demo_${v}_arm64.deb"
            "oxiguitar-demo-$r-1.x86_64.rpm" "oxiguitar-demo-$r-1.aarch64.rpm"
            "oxiguitar-demo-$v-x86_64.flatpak" "oxiguitar-demo-$v-aarch64.flatpak") ;;
        windows) files+=("oxiguitar-demo-$v-windows-x86_64.zip" "oxiguitar-demo-$v-windows-arm64.zip"
            "oxiguitar-demo-$v-windows-x86_64-setup.exe" "oxiguitar-demo-$v-windows-arm64-setup.exe") ;;
        macos) files+=("oxiguitar-demo-$v-macos-universal.zip" "oxiguitar-demo-$v-macos-universal.pkg") ;;
        esac
    done
    for f in "${files[@]}"; do echo "$f" > "$dir/$f"; done
    (cd "$dir" && sha256sum -- "${files[@]}" > SHA256SUMS)
}
passes() { "$assets" demo 1.2.0-rc.1 "$1" > "$work/log" 2>&1 || { cat "$work/log"; fail "$2"; }; }
refuses() { if "$assets" demo 1.2.0-rc.1 "$1" > "$work/log" 2>&1; then cat "$work/log"; fail "$2"; fi; }

# Every system: all 15 files, summed.
release "$work/all" linux windows macos
passes "$work/all" "a whole release was refused"
grep -q '15 files' "$work/log" || fail "a whole release isn't 15 files: $(cat "$work/log")"

# A plugin for Linux only says so, and then only Linux's files are wanted.
release "$work/linux" linux
refuses "$work/linux" "a Linux-only release passed as one for every system"
PLUGIN_SYSTEMS=linux passes "$work/linux" "a Linux-only release was refused with PLUGIN_SYSTEMS=linux"

# A missing file, an empty one, a wrong sum, a file SHA256SUMS doesn't list.
release "$work/r" linux windows macos
rm "$work/r/oxiguitar-demo-1.2.0-rc.1-macos-universal.pkg"
refuses "$work/r" "a release without its .pkg passed"
grep -q 'macos-universal.pkg is missing' "$work/log" || fail "the missing file isn't named"

release "$work/r" linux windows macos
: > "$work/r/oxiguitar-demo_1.2.0-rc.1_amd64.deb"
refuses "$work/r" "an empty .deb passed"

release "$work/r" linux windows macos
echo changed > "$work/r/oxiguitar-demo-1.2.0-rc.1-windows-arm64.zip"
refuses "$work/r" "a file that doesn't match its sum passed"

release "$work/r" linux windows macos
grep -v 'x86_64.flatpak' "$work/r/SHA256SUMS" > "$work/sums" && mv "$work/sums" "$work/r/SHA256SUMS"
refuses "$work/r" "a file SHA256SUMS doesn't list passed"
echo "check-assets.sh: ok"

# check-glibc.sh: a system binary needs some glibc; far above it passes,
# far below it fails; a folder without ELF files is an error.
if ! command -v objdump > /dev/null; then
    echo "objdump isn't installed: check-glibc.sh is not tried"
    exit 0
fi
bin="$(command -v ls)"
if ! objdump -T "$bin" 2> /dev/null | grep -q GLIBC_; then
    echo "$bin doesn't use glibc here: check-glibc.sh is not tried"
    exit 0
fi
mkdir "$work/elf" && cp "$bin" "$work/elf/" && echo "not an ELF file" > "$work/elf/notes.txt"
"$glibc" 99.0 "$work/elf" > "$work/log" 2>&1 || { cat "$work/log"; fail "check-glibc.sh refused glibc 99.0"; }
grep -q 'notes.txt' "$work/log" && fail "check-glibc.sh looked at a file that isn't ELF"
if "$glibc" 2.0 "$work/elf" > "$work/log" 2>&1; then fail "check-glibc.sh passed $bin as needing glibc 2.0 at most"; fi
grep -q 'newer than 2.0' "$work/log" || fail "check-glibc.sh didn't say which glibc: $(cat "$work/log")"
# A plugin file is a tar archive (oxiguitar#347): its library is checked,
# under the plugin file's name.
mkdir "$work/oxp" "$work/stage"
echo '{}' > "$work/stage/manifest.json"
cp "$bin" "$work/stage/plugin.so"
(cd "$work/stage" && tar --format=ustar -cf "$work/oxp/x.oxp" manifest.json plugin.so)
"$glibc" 99.0 "$work/oxp" > "$work/log" 2>&1 || { cat "$work/log"; fail "check-glibc.sh refused a plugin file at glibc 99.0"; }
if "$glibc" 2.0 "$work/oxp" > "$work/log" 2>&1; then fail "check-glibc.sh passed a plugin file's library as needing glibc 2.0 at most"; fi
grep -q 'x.oxp needs glibc' "$work/log" || fail "check-glibc.sh didn't name the plugin file: $(cat "$work/log")"
mkdir "$work/none" && echo text > "$work/none/a.txt"
if "$glibc" 2.35 "$work/none" > "$work/log" 2>&1; then fail "check-glibc.sh passed a folder with no ELF file"; fi
echo "check-glibc.sh: ok"
