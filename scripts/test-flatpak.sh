#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Installs OxiGuitar and plugins from the Flatpak repository SITE/flatpak
# (scripts/flatpak-repo.sh) the way a user would, for this user only, and
# checks them in the sandbox:
#
#   - the app from io.github.mateusrdp.OxiGuitar.flatpakref, which adds the
#     repository (signatures checked with the key it carries) and Flathub,
#     its RuntimeRepo, for the runtime;
#   - oxiguitar.flatpakrepo adds the repository too, and lists the same refs;
#   - each PLUGIN (io.github.mateusrdp.OxiGuitar.Plugin.PLUGIN) from it, whose
#     files must appear in /app/lib/oxiguitar/plugins;
#   - with SAMPLE, a score file, `oxiguitar-cli detect` must find a plugin
#     that reads it, in the sandbox.
#
# The files' Url is the published site's; here it is replaced by SITE's own
# folder. Needs flatpak and bubblewrap working (on Ubuntu 24.04 runners:
# sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0) and
# dbus-run-session. Changes this user's Flatpak installation: for CI.
#
# Usage: scripts/test-flatpak.sh SITE SAMPLE|- [PLUGIN...]
set -euo pipefail
trap 'echo "::error::test-flatpak.sh line $LINENO: $BASH_COMMAND"' ERR

site="$(cd "${1:?usage: test-flatpak.sh SITE SAMPLE|- [PLUGIN...]}" && pwd)"
sample="${2:?}"
shift 2
app=io.github.mateusrdp.OxiGuitar
dir="$site/flatpak"
local_url="file://$dir/repo/"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

[[ -f "$dir/$app.flatpakref" ]] || { echo "test-flatpak.sh: no $app.flatpakref in $dir" >&2; exit 1; }
sed "s|^Url=.*|Url=$local_url|" "$dir/$app.flatpakref" > "$tmp/$app.flatpakref"
sed "s|^Url=.*|Url=$local_url|" "$dir/oxiguitar.flatpakrepo" > "$tmp/oxiguitar.flatpakrepo"
grep -qx "RuntimeRepo=https://dl.flathub.org/repo/flathub.flatpakrepo" "$tmp/$app.flatpakref"

echo "== The repository file"
flatpak --user remote-add --if-not-exists --from oxiguitar-check "$tmp/oxiguitar.flatpakrepo"
flatpak --user remote-ls --all oxiguitar-check | tee "$tmp/listed.txt"
grep -q "$app" "$tmp/listed.txt"
flatpak --user remote-delete oxiguitar-check

echo "== The app, from its .flatpakref"
flatpak --user install -y --noninteractive --from "$tmp/$app.flatpakref"
flatpak --user remotes -d
flatpak --user remotes --columns=name,url | grep -E "^oxiguitar\s+$local_url" > /dev/null \
    || { echo "::error::the .flatpakref didn't add the remote oxiguitar"; exit 1; }
flatpak --user remotes --columns=name | grep -qx flathub \
    || { echo "::error::the .flatpakref's RuntimeRepo didn't add Flathub"; exit 1; }
flatpak --user info "$app"

run() { dbus-run-session -- flatpak run "$@"; }
for plugin in "$@"; do
    echo "== Plugin $plugin"
    flatpak --user install -y --noninteractive oxiguitar "$app.Plugin.$plugin"
    flatpak --user info "$app.Plugin.$plugin"
    # Its files, linked into the app's plugin folder.
    files="$(flatpak --user info --show-location "$app.Plugin.$plugin")/files/plugins"
    for f in "$files"/*.oxp; do
        run --command=test "$app" -s "/app/lib/oxiguitar/plugins/$(basename "$f")" \
            || { echo "::error::$(basename "$f") isn't in /app/lib/oxiguitar/plugins"; exit 1; }
    done
done
run --command=ls "$app" -l /app/lib/oxiguitar/plugins

if [[ "$sample" != - ]]; then
    echo "== Opening $(basename "$sample") in the sandbox"
    sample="$(cd "$(dirname "$sample")" && pwd)/$(basename "$sample")"
    out="$(run --filesystem="$(dirname "$sample"):ro" --command=oxiguitar-cli "$app" detect "$sample")"
    echo "$out"
    grep -q 'read by' <<< "$out" || { echo "::error::no plugin read $(basename "$sample")"; exit 1; }
fi
echo "Installed from the repository and checked: $app ${*/#/$app.Plugin.}"
