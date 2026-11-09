#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Builds the whole site (the apt repository, the dnf repository, the Flatpak
# repository, the public key and the pages that explain them) from the .deb,
# .rpm and .flatpak files in PACKAGES/deb, PACKAGES/rpm and PACKAGES/flatpak, signed with the key GPG_KEY_ID found in the
# keyring GNUPGHOME points at. The site is made from scratch each time; nothing
# of an earlier build is read.
#
# Usage: scripts/build-site.sh PACKAGES SITE
# Environment:
#   GPG_KEY_ID        the signing key's id or fingerprint (required)
#   GPG_PASSPHRASE_FILE  a file holding the key's passphrase (default: none)
#   SITE_URL          where the site is served (default
#                     https://mateusrdp.github.io/oxiguitar-packages)
set -euo pipefail
trap 'echo "::error::build-site.sh line $LINENO: $BASH_COMMAND"' ERR

packages="$(cd "${1:?usage: build-site.sh PACKAGES SITE}" && pwd)"
site="${2:?}"
key="${GPG_KEY_ID:?GPG_KEY_ID is required}"
url="${SITE_URL:-https://mateusrdp.github.io/oxiguitar-packages}"
here="$(cd "$(dirname "$0")/.." && pwd)"

rm -rf "$site"
mkdir -p "$site/apt/pool/main" "$site/rpm"
site="$(cd "$site" && pwd)"

gpg_sign=(gpg --batch --yes --pinentry-mode loopback --local-user "$key")
if [[ -n "${GPG_PASSPHRASE_FILE:-}" ]]; then
    gpg_sign+=(--passphrase-file "$GPG_PASSPHRASE_FILE")
fi

# The public key, for both kinds of repository and for people to read.
gpg --export "$key" > "$site/oxiguitar.gpg"
gpg --armor --export "$key" > "$site/oxiguitar.asc"
fingerprint="$(gpg --with-colons --fingerprint "$key" | awk -F: '/^fpr:/ { print $10; exit }')"

# ---- apt -----------------------------------------------------------------
shopt -s nullglob
debs=("$packages"/deb/*.deb)
rpms=("$packages"/rpm/*.rpm)
[[ ${#debs[@]} -gt 0 || ${#rpms[@]} -gt 0 ]] || { echo "build-site.sh: no packages in $packages" >&2; exit 1; }

if [[ ${#debs[@]} -gt 0 ]]; then
    cp "${debs[@]}" "$site/apt/pool/main/"
fi
suite="$site/apt/dists/stable"
for arch in amd64 arm64; do
    dir="$suite/main/binary-$arch"
    mkdir -p "$dir"
    (cd "$site/apt" && apt-ftparchive --arch "$arch" packages pool > "$dir/Packages")
    gzip -9nk "$dir/Packages"
    xz -9k "$dir/Packages"
done
(
    cd "$site/apt"
    apt-ftparchive \
        -o APT::FTPArchive::Release::Origin=OxiGuitar \
        -o APT::FTPArchive::Release::Label=OxiGuitar \
        -o APT::FTPArchive::Release::Suite=stable \
        -o APT::FTPArchive::Release::Codename=stable \
        -o APT::FTPArchive::Release::Architectures="amd64 arm64" \
        -o APT::FTPArchive::Release::Components=main \
        -o APT::FTPArchive::Release::Description="OxiGuitar and its plugins" \
        release dists/stable > dists/stable/Release
)
"${gpg_sign[@]}" --armor --detach-sign --output "$suite/Release.gpg" "$suite/Release"
"${gpg_sign[@]}" --clearsign --output "$suite/InRelease" "$suite/Release"

# ---- dnf -----------------------------------------------------------------
if [[ ${#rpms[@]} -gt 0 ]]; then
    # A noarch package (the sound-set installer) goes into every architecture's
    # repository, as the repository file asks for $basearch only.
    for arch in x86_64 aarch64; do mkdir -p "$site/rpm/$arch"; done
    for rpm in "${rpms[@]}"; do
        arch="$(rpm -qp --qf '%{ARCH}' "$rpm" 2> /dev/null)"
        if [[ "$arch" == noarch ]]; then
            for dir in "$site"/rpm/*/; do cp "$rpm" "$dir"; done
        else
            mkdir -p "$site/rpm/$arch"
            cp "$rpm" "$site/rpm/$arch/"
        fi
    done
    sign_cmd="gpg --batch --yes --pinentry-mode loopback"
    [[ -n "${GPG_PASSPHRASE_FILE:-}" ]] && sign_cmd="$sign_cmd --passphrase-file $GPG_PASSPHRASE_FILE"
    for dir in "$site"/rpm/*/; do
        rpmsign --addsign \
            --define "_gpg_name $key" \
            --define "__gpg_sign_cmd %{__gpg} $sign_cmd --no-verbose --no-armor --no-secmem-warning -u \"%{_gpg_name}\" -sbo %{__signature_filename} --digest-algo sha256 %{__plaintext_filename}" \
            "$dir"*.rpm > /dev/null
        createrepo_c --quiet "$dir"
        "${gpg_sign[@]}" --armor --detach-sign --output "$dir/repodata/repomd.xml.asc" "$dir/repodata/repomd.xml"
    done
fi

# ---- Flatpak -------------------------------------------------------------
# Bundles come with releases made since #163; until one is there, no
# Flatpak repository (scripts/flatpak-repo.sh).
flatpaks=("$packages"/flatpak/*.flatpak)
if [[ ${#flatpaks[@]} -gt 0 ]]; then
    GPG_KEY_ID="$key" SITE_URL="$url" "$here/scripts/flatpak-repo.sh" "$packages/flatpak" "$site/flatpak"
else
    echo "::notice::No Flatpak bundle in any published release yet: no Flatpak repository."
fi

# ---- the files that tell people how to use it ----------------------------
cat > "$site/oxiguitar.sources" <<SOURCES
Types: deb
URIs: $url/apt
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/oxiguitar.gpg
SOURCES
cat > "$site/oxiguitar.repo" <<REPO
[oxiguitar]
name=OxiGuitar
baseurl=$url/rpm/\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=$url/oxiguitar.asc
REPO
sed -e "s|@URL@|$url|g" -e "s|@FINGERPRINT@|$fingerprint|g" "$here/site-src/index.html" > "$site/index.html"
touch "$site/.nojekyll"

# What is in it, for the log and the page.
{
    echo "Packages in the apt repository:"
    for arch in amd64 arm64; do
        grep -E '^(Package|Version):' "$suite/main/binary-$arch/Packages" | paste - - | sed "s/^/  [$arch] /"
    done
    if [[ -d "$site/flatpak/repo" ]]; then
        echo "Refs in the Flatpak repository:"
        ostree --repo="$site/flatpak/repo" refs | grep -E '^(app|runtime)/' | sort | while read -r ref; do
            printf '  %s %s\n' "$ref" "$(ostree --repo="$site/flatpak/repo" show "$ref" | awk '/^Date:/ { print $2; exit }')"
        done
    fi
} | tee "$site/packages.txt"
