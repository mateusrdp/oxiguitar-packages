#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# What CI's Repositories job does, on your machine and in a temporary
# folder: makes the test packages (scripts/make-test-packages.sh), signs a
# site with them using a throwaway key in a throwaway GnuPG home
# (scripts/build-site.sh), and checks the Flatpak repository. With
# --install, it then installs both test packages from that site with apt and
# dnf, in Debian and Fedora containers (scripts/test-install.sh; needs
# docker, and pulls the two images): nothing is installed on this machine.
# scripts/test-all.py runs it as two stages.
#
# Usage: tests/test-site.sh [--install]
# Needs gpg, dpkg-deb, apt-ftparchive, rpmbuild, createrepo_c, flatpak and
# ostree (on Debian and Ubuntu: apt-utils createrepo-c rpm gnupg flatpak
# ostree appstream appstream-compose).
set -euo pipefail
cd "$(dirname "$0")/.."
install=0
case "${1:-}" in
"") ;;
--install) install=1 ;;
*) echo "usage: tests/test-site.sh [--install]" >&2; exit 2 ;;
esac
work="$(mktemp -d)"
cleanup() {
    gpgconf --kill gpg-agent > /dev/null 2>&1 || true
    rm -rf "$work"
}
trap cleanup EXIT
fail() { echo "FAILED: $*" >&2; exit 1; }

export GNUPGHOME="$work/gnupg"
mkdir -m 700 "$GNUPGHOME"
gpg --batch --quiet --passphrase '' --quick-generate-key 'OxiGuitar test <test@example.invalid>' rsa4096 sign never
key="$(gpg --with-colons --list-secret-keys | awk -F: '/^fpr:/ { print $10; exit }')"
[[ -n "$key" ]] || fail "no throwaway key was made"

scripts/make-test-packages.sh scripts/plugin-package "$work/packages"
GPG_KEY_ID="$key" scripts/build-site.sh "$work/packages" "$work/site"

# The test plugin's extension is in the Flatpak repository, signed; with no
# OxiGuitar bundle there is no .flatpakref.
ostree --repo="$work/site/flatpak/repo" refs |
    grep -qx "runtime/io.github.mateusrdp.OxiGuitar.Plugin.test/$(uname -m)/stable" ||
    fail "the test plugin's Flatpak extension isn't in the repository"
[[ -s "$work/site/flatpak/repo/summary.sig" ]] || fail "the Flatpak repository's summary isn't signed"
grep -q '^GPGKey=' "$work/site/flatpak/oxiguitar.flatpakrepo" || fail "oxiguitar.flatpakrepo carries no key"
[[ ! -e "$work/site/flatpak/io.github.mateusrdp.OxiGuitar.flatpakref" ]] ||
    fail "a .flatpakref was made without an OxiGuitar bundle"
echo "the site: ok"

if ((install)); then
    scripts/test-install.sh "$work/site" oxiguitar-test /usr/lib/oxiguitar/plugins/test.oxp
    scripts/test-install.sh "$work/site" oxiguitar-testall /usr/share/oxiguitar-testall/hello
    echo "installing from the site: ok"
fi
