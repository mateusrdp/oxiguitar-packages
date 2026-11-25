#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Builds the two trial plugins' release files for the system this runs on,
# the way a plugin repository's build-oxp.sh does (OxiGuitar's
# docs/plugins/template), so that .github/workflows/plugin-release-try.yml can
# try plugin-release.yml on them: dist/trial-first-VERSION-SYSTEM-ARCH.oxp and
# dist/trial-second-..., universal on macOS (needs both Rust targets). Each
# is an uncompressed tar archive (oxiguitar#347): manifest.json first, the
# library second as plugin.so, plugin.dll or plugin.dylib.
set -euo pipefail

cd "$(dirname "$0")"
version="$(cargo pkgid -p oxiguitar-trial-first-plugin)"
version="${version##*[#@]}"
host="$(rustc -vV | sed -n 's/^host: //p')"
mkdir -p dist

# pack LIBRARY MANIFEST OUT: the plugin file OUT. COPYFILE_DISABLE keeps
# macOS's tar from adding ._ files.
pack() {
    local ext="${1##*.}" stage
    stage="$(mktemp -d)"
    cp "$2" "$stage/manifest.json"
    cp "$1" "$stage/plugin.$ext"
    (cd "$stage" && COPYFILE_DISABLE=1 tar --format=ustar -cf - manifest.json "plugin.$ext") > "$3"
    rm -rf "$stage"
}

for name in trial-first trial-second; do
    manifest="${name#trial-}/manifest.json"
    package="oxiguitar-$name-plugin"
    library="${package//-/_}"
    build() {
        # OXIGUITAR_IGNORE_RUST_VERSION: scripts/test-all.py --ignore-rust-version.
        cargo rustc --locked --release ${OXIGUITAR_IGNORE_RUST_VERSION:+--ignore-rust-version} \
            -p "$package" --features oxp --crate-type cdylib "$@"
    }
    case "$host" in
        *apple*)
            out="dist/$name-$version-macos-universal.oxp"
            for target in aarch64-apple-darwin x86_64-apple-darwin; do
                build --target "$target"
            done
            lipo -create -output "target/lib$library-universal.dylib" \
                "target/aarch64-apple-darwin/release/lib$library.dylib" \
                "target/x86_64-apple-darwin/release/lib$library.dylib"
            pack "target/lib$library-universal.dylib" "$manifest" "$out"
            ;;
        *windows*)
            arch="${host%%-*}"
            [[ "$arch" == aarch64 ]] && arch=arm64
            out="dist/$name-$version-windows-$arch.oxp"
            build
            pack "target/release/$library.dll" "$manifest" "$out"
            ;;
        *)
            out="dist/$name-$version-linux-${host%%-*}.oxp"
            build
            pack "target/release/lib$library.so" "$manifest" "$out"
            ;;
    esac
    echo "$out"
done
