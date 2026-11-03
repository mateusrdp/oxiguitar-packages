#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Builds the two trial plugins' release files for the system this runs on,
# the way a plugin repository's build-oxp.sh does (OxiGuitar's
# docs/plugins/template), so that .github/workflows/plugin-release-try.yml can
# try plugin-release.yml on them: dist/trial-first-VERSION-SYSTEM-ARCH.oxp and
# dist/trial-second-..., universal on macOS (needs both Rust targets).
set -euo pipefail

cd "$(dirname "$0")"
version="$(cargo pkgid -p oxiguitar-trial-first-plugin)"
version="${version##*[#@]}"
host="$(rustc -vV | sed -n 's/^host: //p')"
mkdir -p dist

for name in trial-first trial-second; do
    package="oxiguitar-$name-plugin"
    library="${package//-/_}"
    build() {
        cargo rustc --locked --release -p "$package" --features oxp --crate-type cdylib "$@"
    }
    case "$host" in
        *apple*)
            out="dist/$name-$version-macos-universal.oxp"
            for target in aarch64-apple-darwin x86_64-apple-darwin; do
                build --target "$target"
            done
            lipo -create -output "$out" \
                "target/aarch64-apple-darwin/release/lib$library.dylib" \
                "target/x86_64-apple-darwin/release/lib$library.dylib"
            ;;
        *windows*)
            arch="${host%%-*}"
            [[ "$arch" == aarch64 ]] && arch=arm64
            out="dist/$name-$version-windows-$arch.oxp"
            build
            cp "target/release/$library.dll" "$out"
            ;;
        *)
            out="dist/$name-$version-linux-${host%%-*}.oxp"
            build
            cp "target/release/lib$library.so" "$out"
            ;;
    esac
    echo "$out"
done
