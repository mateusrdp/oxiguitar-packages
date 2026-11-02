#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Writes the three winget manifest files of a plugin release (version,
# installer, default locale) for the first submission of a package to
# microsoft/winget-pkgs, which is made by hand; the releases after it are
# updated by wingetcreate in the plugin repository's publish workflow.
#
# The installers are the per-user setup .exe files plugin-release.yml makes
# (Inno Setup, no administrator rights), x64 and arm64.
#
# Usage: scripts/make-winget-manifests.sh REPOSITORY TAG OUT-DIR
#   REPOSITORY  owner/name, such as mateusrdp/oxiguitar-midi
#   OUT-DIR     gets PACKAGE-ID.yaml, PACKAGE-ID.installer.yaml and
#               PACKAGE-ID.locale.en-US.yaml
# Environment:
#   WINGET_SAMPLE=1  use made-up addresses and sums (for the schema check in CI)
# Needs gh (GH_TOKEN), curl.
set -euo pipefail
trap 'echo "::error::make-winget-manifests.sh line $LINENO: $BASH_COMMAND"' ERR

repo="${1:?usage: make-winget-manifests.sh REPOSITORY TAG OUT-DIR}"
tag="${2:?}"
out="${3:?}"
version="${tag#v}"
schema="1.10.0"

# The winget id of each plugin: mateusrdp.OxiGuitar.<Name>.
suffix="${repo#mateusrdp/oxiguitar-}"
case "$suffix" in
    guitarpro) ident="GuitarPro" title="Guitar Pro" ;;
    midi) ident="MIDI" title="MIDI" ;;
    wav) ident="WAV" title="WAV export" ;;
    wasapi) ident="WASAPI" title="WASAPI audio output" ;;
    nam) ident="NAM" title="NAM amp models" ;;
    *) echo "make-winget-manifests.sh: no winget package planned for $repo" >&2; exit 2 ;;
esac
id="mateusrdp.OxiGuitar.$ident"

if [[ "${WINGET_SAMPLE:-}" == 1 ]]; then
    description="A sample plugin description"
    license="GPL-3.0-or-later"
    file_name="oxiguitar-$suffix-$version-windows"
    sum_x64="$(printf 'x64' | sha256sum | cut -d' ' -f1)"
    sum_arm64="$(printf 'arm64' | sha256sum | cut -d' ' -f1)"
else
    description="$(gh api "repos/$repo" --jq '.description // ""')"
    description="${description%.}"
    license="$(gh api "repos/$repo" --jq '.license.spdx_id // "GPL-3.0-or-later"')"
    file_name="oxiguitar-$suffix-$version-windows"
    sums="$(curl -fsSL --retry 5 "https://github.com/$repo/releases/download/$tag/SHA256SUMS")"
    sum_x64="$(awk -v n="$file_name-x86_64-setup.exe" '$2 == n || $2 == "*" n { print $1 }' <<< "$sums")"
    sum_arm64="$(awk -v n="$file_name-arm64-setup.exe" '$2 == n || $2 == "*" n { print $1 }' <<< "$sums")"
    [[ -n "$sum_x64" && -n "$sum_arm64" ]] || { echo "::error::the setup files of $repo $tag are not in SHA256SUMS"; exit 1; }
fi
[[ -n "$description" ]] || description="A plugin for OxiGuitar"
base="https://github.com/$repo/releases/download/$tag/$file_name"

mkdir -p "$out"
cat > "$out/$id.yaml" <<YAML
# yaml-language-server: \$schema=https://aka.ms/winget-manifest.version.$schema.schema.json
PackageIdentifier: $id
PackageVersion: $version
DefaultLocale: en-US
ManifestType: version
ManifestVersion: $schema
YAML

dependencies=""
if [[ "$suffix" == nam ]]; then
    dependencies=$'Dependencies:\n  PackageDependencies:\n    - PackageIdentifier: mateusrdp.OxiGuitar.MIDI\n      MinimumVersion: 0.1.0\n'
fi
cat > "$out/$id.installer.yaml" <<YAML
# yaml-language-server: \$schema=https://aka.ms/winget-manifest.installer.$schema.schema.json
PackageIdentifier: $id
PackageVersion: $version
InstallerLocale: en-US
InstallerType: inno
Scope: user
UpgradeBehavior: install
${dependencies}Installers:
  - Architecture: x64
    InstallerUrl: $base-x86_64-setup.exe
    InstallerSha256: ${sum_x64^^}
  - Architecture: arm64
    InstallerUrl: $base-arm64-setup.exe
    InstallerSha256: ${sum_arm64^^}
ManifestType: installer
ManifestVersion: $schema
YAML

cat > "$out/$id.locale.en-US.yaml" <<YAML
# yaml-language-server: \$schema=https://aka.ms/winget-manifest.defaultLocale.$schema.schema.json
PackageIdentifier: $id
PackageVersion: $version
PackageLocale: en-US
Publisher: Mateus Rocha de Paula
PublisherUrl: https://github.com/mateusrdp
PackageName: OxiGuitar $title plugin
PackageUrl: https://github.com/$repo
License: $license
LicenseUrl: https://github.com/$repo/blob/main/LICENSE
ShortDescription: $description
Tags:
  - guitar
  - tablature
  - music
  - oxiguitar
ManifestType: defaultLocale
ManifestVersion: $schema
YAML
echo "$out: $id $version"
