#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Builds the Flatpak of one plugin (#163; the core's docs/design/flatpak.md):
# io.github.mateusrdp.OxiGuitar.Plugin.NAME, an extension of the OxiGuitar
# Flatpak. The app's extension point is lib/oxiguitar with merge-dirs
# plugins, so the extension is mounted at /app/lib/oxiguitar/NAME and its
# files in plugins/ appear in /app/lib/oxiguitar/plugins, the system plugin
# folder OxiGuitar derives. It holds the plugin files under the names the
# .deb gives them, and an AppStream add-on so software centres list it under
# OxiGuitar. Needs flatpak, ostree and appstreamcli (Ubuntu: flatpak,
# appstream, appstream-compose); no SDK and no sandbox: the files are only copied. Used by
# .github/workflows/plugin-release.yml.
#
# Usage: scripts/plugin-package/flatpak.sh NAME VERSION ARCH OUT-DIR SRC[:DEST]...
#   ARCH     x86_64 or aarch64, the machine's own (flatpak build-export
#            exports for the host's architecture)
#   SRC      a built .oxp file; DEST the name it is installed under
#            (default NAME.oxp), as for deb.sh
# Reads, from the environment:
#   PLUGIN_TITLE        shown name, "MIDI (SoundFont, SFZ)" (default NAME)
#   PLUGIN_DESCRIPTION  one line (required)
#   PLUGIN_HOMEPAGE     the repository's address
#   PLUGIN_LICENSE      an SPDX expression (default GPL-3.0-or-later)
#   SOURCE_DATE_EPOCH   the commit's time (default: now)
# Writes: OUT-DIR/oxiguitar-NAME-VERSION-ARCH.flatpak

set -euo pipefail
trap 'echo "::error::flatpak.sh line $LINENO: $BASH_COMMAND"' ERR

name="${1:?usage: flatpak.sh NAME VERSION ARCH OUT-DIR SRC[:DEST]...}"
version="${2:?}"
arch="${3:?}"
out_dir="${4:?}"
shift 4
[[ $# -gt 0 ]] || { echo "flatpak.sh: no plugin file given" >&2; exit 2; }

app=io.github.mateusrdp.OxiGuitar
branch=stable
id="$app.Plugin.$name"
case "$arch" in
    x86_64 | aarch64) ;;
    *) echo "flatpak.sh: no Flatpak architecture for $arch" >&2; exit 2 ;;
esac
if [[ "$(flatpak --default-arch)" != "$arch" ]]; then
    echo "flatpak.sh: this machine is $(flatpak --default-arch), not $arch" >&2
    exit 2
fi
title="${PLUGIN_TITLE:-$name}"
description="${PLUGIN_DESCRIPTION:?PLUGIN_DESCRIPTION is required}"
homepage="${PLUGIN_HOMEPAGE:-https://github.com/mateusrdp/oxiguitar}"
license="${PLUGIN_LICENSE:-GPL-3.0-or-later}"
epoch="${SOURCE_DATE_EPOCH:-$(date +%s)}"

xml() { # escapes text for XML
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' <<< "$1"
}

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
build="$work/build"
mkdir -p "$build/files/plugins" "$build/files/share/metainfo"

for spec in "$@"; do
    src="${spec%%:*}"
    dest="$name.oxp"
    [[ "$spec" == *:* ]] && dest="${spec#*:}"
    [[ -s "$src" ]] || { echo "flatpak.sh: $src is missing or empty" >&2; exit 2; }
    install -m644 "$src" "$build/files/plugins/$dest"
done

# An extension of the app's branch: Flatpak mounts it only into that app.
cat > "$build/metadata" << METADATA
[Runtime]
name=$id

[ExtensionOf]
ref=app/$app/$arch/$branch
METADATA

cat > "$build/files/share/metainfo/$id.metainfo.xml" << METAINFO
<?xml version="1.0" encoding="UTF-8"?>
<component type="addon">
  <id>$id</id>
  <extends>$app</extends>
  <name>$(xml "$title")</name>
  <summary>$(xml "${description%.}")</summary>
  <description>
    <p>The $(xml "$title") plugin for OxiGuitar. $(xml "$description")</p>
  </description>
  <developer id="io.github.mateusrdp">
    <name>Mateus Rocha de Paula</name>
  </developer>
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>$(xml "$license")</project_license>
  <url type="homepage">$(xml "$homepage")</url>
  <releases>
    <release version="$(xml "$version")" date="$(date -u -d "@$epoch" +%Y-%m-%d)"/>
  </releases>
</component>
METAINFO
appstreamcli validate --no-net "$build/files/share/metainfo/$id.metainfo.xml" || true
# The catalogue Flatpak's repository and the software centres read.
appstreamcli compose --origin="$id" --prefix=/ --result-root="$build/files" \
    --data-dir="$build/files/share/app-info/xmls" "$build/files" > "$work/compose.log" 2>&1 \
    || { cat "$work/compose.log" >&2; exit 1; }
test -s "$build/files/share/app-info/xmls/$id.xml.gz" \
    || { cat "$work/compose.log" >&2; echo "flatpak.sh: appstreamcli wrote no catalogue" >&2; exit 1; }

flatpak build-export --runtime --files=files --arch="$arch" --timestamp="@$epoch" \
    --subject="$title $version" "$work/repo" "$build" "$branch" > /dev/null
mkdir -p "$out_dir"
bundle="$out_dir/oxiguitar-$name-$version-$arch.flatpak"
flatpak build-bundle --runtime --arch="$arch" "$work/repo" "$bundle" "$id" "$branch"
echo "$bundle: $id ($arch, $branch), $(du -h "$bundle" | cut -f1)"
