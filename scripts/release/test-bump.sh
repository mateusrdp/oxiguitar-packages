#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Tries scripts/release/bump.sh on made-up repositories shaped like ours: a
# single plugin (with a `needs` entry and a second manifest, as NAM has), a
# workspace of several plugins (as oxiguitar-guitarpro), a repository with a
# VERSION file (the sound-set installer), and the refusals. Run by CI.
set -euo pipefail

bump="$(cd "$(dirname "$0")" && pwd)/bump.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail() { echo "FAILED: $*" >&2; exit 1; }

repo() {  # NAME: an empty git repository
    mkdir -p "$work/$1"
    git -C "$work/$1" init -q
}
commit() { git -C "$work/$1" add -A; }

# A single plugin, like oxiguitar-nam.
repo single
cd "$work/single"
cat > Cargo.toml <<'T'
[package]
name = "oxiguitar-nam-plugin"
version = "0.1.0"

[dependencies]
serde = { version = "0.1.0" }
T
cat > manifest.json <<'T'
{
  "interface": "1.4",
  "id": "oxiguitar.nam",
  "version": "0.1.0",
  "needs": [{ "id": "oxiguitar.midi", "version": "0.1.0" }]
}
T
cat > manifest-x86-64-v3.json <<'T'
{
  "id": "oxiguitar.nam",
  "version": "0.1.0",
  "needs": [
    {
      "id": "oxiguitar.midi",
      "version": "0.1.0"
    }
  ]
}
T
cat > Cargo.lock <<'T'
[[package]]
name = "oxiguitar-nam-plugin"
version = "0.1.0"
dependencies = [
 "serde",
]

[[package]]
name = "serde"
version = "0.1.0"
source = "registry+https://github.com/rust-lang/crates.io-index"
T
printf '# Changelog\n\n## [Unreleased]\n\n### Added\n\n- A hint.\n\n## [0.1.0] - 2026-11-02\n\n- First.\n' > CHANGELOG.md
commit single
"$bump" . 0.2.0 2026-11-04 > /dev/null
grep -q '^version = "0.2.0"' Cargo.toml || fail "single: Cargo.toml"
grep -q 'serde = { version = "0.1.0" }' Cargo.toml || fail "single: a dependency's version changed"
grep -q '^  "version": "0.2.0",' manifest.json || fail "single: manifest.json"
grep -q '"oxiguitar.midi", "version": "0.1.0"' manifest.json || fail "single: the needs entry changed"
grep -q '^  "version": "0.2.0",' manifest-x86-64-v3.json || fail "single: the second manifest"
grep -q '^      "version": "0.1.0"' manifest-x86-64-v3.json || fail "single: the second manifest's needs entry changed"
[[ "$(grep -c 'version = "0.2.0"' Cargo.lock)" == 1 ]] || fail "single: Cargo.lock's own crate"
grep -A1 'name = "serde"' Cargo.lock | grep -q '0.1.0' || fail "single: a crate from crates.io changed"
python3 - <<'P' || fail "single: CHANGELOG.md"
import pathlib
t = pathlib.Path("CHANGELOG.md").read_text()
assert t.index("## [Unreleased]\n\n## [0.2.0] - 2026-11-04\n\n### Added\n\n- A hint.\n\n## [0.1.0]") > 0, t
P
# Now [Unreleased] is empty: a second release is refused, nothing changed.
before="$(git diff | sha256sum)"
! "$bump" . 0.3.0 2>/dev/null || fail "single: an empty [Unreleased] was accepted"
[[ "$(git diff | sha256sum)" == "$before" ]] || fail "single: a refused bump changed files"

# A workspace of several plugins, like oxiguitar-guitarpro.
repo workspace
cd "$work/workspace"
printf '[workspace]\nmembers = ["plugins/*"]\n\n[workspace.package]\nversion = "1.2.3"\n' > Cargo.toml
for p in gp gp5; do
    mkdir -p "plugins/$p"
    printf '[package]\nname = "oxiguitar-%s-plugin"\nversion.workspace = true\n' "$p" > "plugins/$p/Cargo.toml"
    printf '{\n  "id": "oxiguitar.%s",\n  "version": "1.2.3"\n}\n' "$p" > "plugins/$p/manifest.json"
done
mkdir -p fuzz
printf '[package]\nname = "fuzz"\nversion = "0.0.0"\n' > fuzz/Cargo.toml
printf '[[package]]\nname = "oxiguitar-gp-plugin"\nversion = "1.2.3"\n\n[[package]]\nname = "oxiguitar-gp5-plugin"\nversion = "1.2.3"\n' > Cargo.lock
printf '## [Unreleased]\n\n- Faster.\n' > CHANGELOG.md
commit workspace
"$bump" . 1.3.0 2026-11-04 > /dev/null
grep -q '^version = "1.3.0"' Cargo.toml || fail "workspace: Cargo.toml"
for p in gp gp5; do grep -q '"version": "1.3.0"' "plugins/$p/manifest.json" || fail "workspace: plugins/$p/manifest.json"; done
grep -q 'version = "0.0.0"' fuzz/Cargo.toml || fail "workspace: the fuzz crate's version changed"
[[ "$(grep -c 'version = "1.3.0"' Cargo.lock)" == 2 ]] || fail "workspace: Cargo.lock"
grep -q '^## \[1.3.0\] - 2026-11-04$' CHANGELOG.md || fail "workspace: CHANGELOG.md"

# A VERSION file and a first release, like the sound-set installer.
repo installer
cd "$work/installer"
echo 0.1.0 > VERSION
printf '## [Unreleased]\n\n### Added\n\n- The sets.\n' > CHANGELOG.md
commit installer
! "$bump" . 0.1.0 2>/dev/null || fail "installer: the same version was accepted without FIRST_RELEASE"
! "$bump" . 0.0.9 2>/dev/null || fail "installer: a lower version was accepted"
FIRST_RELEASE=true "$bump" . 0.1.0 2026-11-04 > /dev/null
[[ "$(cat VERSION)" == 0.1.0 ]] || fail "installer: VERSION"
grep -q '^## \[0.1.0\] - 2026-11-04$' CHANGELOG.md || fail "installer: CHANGELOG.md"
! "$bump" . v1 2>/dev/null || fail "installer: a malformed version was accepted"

echo "bump.sh: all checks passed"
