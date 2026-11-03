#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Prepares the release of a repository that has no scripts/release/bump.sh of
# its own (every plugin repository, and the sound-set installer): run by the
# Release workflow in the repository's checkout, never by hand. Every place
# that names the version takes the new one, and the CHANGELOG's [Unreleased]
# section becomes the release's. Nothing is committed.
#
#   - the version in the root Cargo.toml ([package] or [workspace.package]),
#     or else in a VERSION file;
#   - every other Cargo.toml whose [package] version is the same;
#   - every manifest*.json's top-level "version" (not a `needs` entry's);
#   - in every Cargo.lock, the repository's own crates (those without a
#     `source`) at that version;
#   - VERSION, when there is one;
#   - CHANGELOG.md: "## [Unreleased]" stays, empty, and its text goes under
#     "## [VERSION] - DATE".
#
# Usage: bump.sh DIR VERSION [YYYY-MM-DD]
#
# Fails, changing nothing, when [Unreleased] is empty or VERSION is not
# higher than the current one. FIRST_RELEASE=true (no v* tag yet) also
# accepts the current version itself, so a repository's first release keeps
# the version it was made with (oxiguitar-eq's 0.1.0).
set -euo pipefail

exec python3 -I - "$@" <<'PY'
import datetime, os, pathlib, re, subprocess, sys

args = sys.argv[1:]
if not 2 <= len(args) <= 3:
    sys.exit("usage: bump.sh DIR VERSION [YYYY-MM-DD]")
root = pathlib.Path(args[0])
new = args[1].removeprefix("v")
date = args[2] if len(args) == 3 else datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")
if not re.fullmatch(r"\d+\.\d+\.\d+", new):
    sys.exit(f"{new!r} is not a version like 0.2.0")
first = os.environ.get("FIRST_RELEASE") == "true"

tracked = subprocess.run(["git", "ls-files"], cwd=root, capture_output=True, text=True, check=True).stdout.split()
changes = {}  # path -> new text, written only once everything is ready


def read(rel):
    return changes.get(rel) or (root / rel).read_text(encoding="utf-8")


# A [package] or [workspace.package] table's own version line.
SECTION = r'(^\[(?:workspace\.)?package\][^\[]*?^version = )"([^"]+)"'

if "VERSION" in tracked:
    old = read("VERSION").strip()
else:
    m = re.search(SECTION, read("Cargo.toml"), re.M | re.S) if "Cargo.toml" in tracked else None
    if not m:
        sys.exit("no version found: neither a VERSION file nor a version in the root Cargo.toml")
    old = m.group(2)
key = lambda v: tuple(int(x) for x in v.split("."))
if key(new) < key(old) or (key(new) == key(old) and not first):
    sys.exit(f"{new} is not higher than the current version {old}")

if new != old:
    if "VERSION" in tracked:
        changes["VERSION"] = new + "\n"
    for rel in [p for p in tracked if p == "Cargo.toml" or p.endswith("/Cargo.toml")]:
        out, n = re.subn(SECTION.replace('"([^"]+)"', '"' + re.escape(old) + '"'), r'\1"' + new + '"',
                         read(rel), count=1, flags=re.M | re.S)
        if n:
            changes[rel] = out
    if "Cargo.toml" in tracked and "Cargo.toml" not in changes and "VERSION" not in tracked:
        sys.exit("Cargo.toml: its version was not changed")
    for rel in [p for p in tracked if re.search(r"(^|/)manifest[^/]*\.json$", p)]:
        out, n = re.subn(r'^(  "version": )"' + re.escape(old) + '"', r'\1"' + new + '"', read(rel), count=1, flags=re.M)
        if n:
            changes[rel] = out
        elif re.search(r'^  "version":', read(rel), re.M):
            sys.exit(f"{rel}: its version is not {old}")
    for rel in [p for p in tracked if p == "Cargo.lock" or p.endswith("/Cargo.lock")]:
        out, n = re.subn(r'(\[\[package\]\]\nname = "[^"]+"\nversion = )"' + re.escape(old) + r'"(\n(?!source = ))',
                         r'\1"' + new + r'"\2', read(rel))
        if n:
            changes[rel] = out

changelog = read("CHANGELOG.md")
m = re.search(r"^## \[Unreleased\]\n(.*?)(?=^## \[|\Z)", changelog, re.M | re.S)
if not m or not m.group(1).strip():
    sys.exit("CHANGELOG.md: nothing under [Unreleased]; write what changed first")
body = m.group(1).strip("\n")
out = changelog[:m.start()] + f"## [Unreleased]\n\n## [{new}] - {date}\n\n{body}\n\n" + changelog[m.end():]
changes["CHANGELOG.md"] = out.rstrip("\n") + "\n"

for rel, text in changes.items():
    (root / rel).write_text(text, encoding="utf-8")
print(f"{old} -> {new} ({date}): " + ", ".join(sorted(changes)))
PY
