#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Serves SITE on this machine and installs PACKAGE from it the way a user
# would: with apt in a Debian container and with dnf in a Fedora container,
# both checking the signatures, then checks the plugin file is in place.
#
# Usage: scripts/test-install.sh SITE PACKAGE FILE
#   PACKAGE  the package to install, such as oxiguitar-midi
#   FILE     the file it must leave, such as /usr/lib/oxiguitar/plugins/midi.oxp
set -euo pipefail
trap 'echo "::error::test-install.sh line $LINENO: $BASH_COMMAND"' ERR

site="$(cd "${1:?usage: test-install.sh SITE PACKAGE FILE}" && pwd)"
package="${2:?}"
file="${3:?}"
port=8765
base="http://localhost:$port"

python3 -m http.server "$port" --bind 127.0.0.1 --directory "$site" > /dev/null 2>&1 &
server=$!
trap 'kill $server 2> /dev/null || true' EXIT
for _ in $(seq 1 50); do
    curl -fsS "$base/oxiguitar.gpg" -o /dev/null 2> /dev/null && break
    sleep 0.2
done

echo "== apt (Debian)"
docker run --rm --network host debian:stable bash -euo pipefail -c "
    apt-get update -qq && apt-get install -y -qq curl ca-certificates > /dev/null
    install -d -m 0755 /etc/apt/keyrings
    curl -fsS $base/oxiguitar.gpg -o /etc/apt/keyrings/oxiguitar.gpg
    curl -fsS $base/oxiguitar.sources | sed 's|^URIs: .*|URIs: $base/apt|' > /etc/apt/sources.list.d/oxiguitar.sources
    apt-get update
    apt-get install -y $package
    test -e $file
    dpkg -s $package | grep -E '^(Package|Version|Status):'
    echo 'apt: ok'
"

echo "== dnf (Fedora)"
docker run --rm --network host fedora:latest bash -euo pipefail -c "
    curl -fsS $base/oxiguitar.repo | sed -e 's|^baseurl=.*|baseurl=$base/rpm/\\\$basearch|' -e 's|^gpgkey=.*|gpgkey=$base/oxiguitar.asc|' > /etc/yum.repos.d/oxiguitar.repo
    dnf install -y $package
    test -e $file
    rpm -q $package
    echo 'dnf: ok'
"
