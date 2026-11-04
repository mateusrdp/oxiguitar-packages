#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Makes small test packages (a made-up plugin, x86_64 and aarch64, with
# OxiGuitar's own packaging scripts, and a made-up package that is the same on
# every architecture, like the sound-set installer's), so the build of the site and its install
# test don't depend on any release existing.
#
# Usage: scripts/make-test-packages.sh SCRIPTS-DIR OUT-DIR
#   SCRIPTS-DIR  the packaging scripts, this repository's scripts/plugin-package
set -euo pipefail
tools="$(cd "${1:?usage: make-test-packages.sh SCRIPTS-DIR OUT-DIR}" && pwd)"
out="${2:?}"
mkdir -p "$out/deb" "$out/rpm"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
head -c 4096 /dev/urandom > "$work/test.oxp"
export PLUGIN_DESCRIPTION="A made-up plugin that tests this repository."
for arch in x86_64 aarch64; do
    "$tools/deb.sh" test 0.0.1 "$arch" "$out/deb" "$work/test.oxp" > /dev/null
done
# rpmbuild builds for the machine's own processor only.
"$tools/rpm.sh" test 0.0.1 "$(uname -m)" "$out/rpm" "$work/test.oxp" > /dev/null

# An architecture-independent package: Architecture: all and noarch.
tree="$work/testall"
mkdir -p "$tree/DEBIAN" "$tree/usr/share/oxiguitar-testall"
echo hello > "$tree/usr/share/oxiguitar-testall/hello"
printf 'Package: oxiguitar-testall\nVersion: 0.0.1\nSection: sound\nPriority: optional\nArchitecture: all\nMaintainer: Test <test@example.invalid>\nDescription: A made-up package for every architecture\n It tests this repository.\n' > "$tree/DEBIAN/control"
dpkg-deb --root-owner-group -Zxz --build "$tree" "$out/deb/oxiguitar-testall_0.0.1_all.deb" > /dev/null
top="$work/rpmbuild"
mkdir -p "$top"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cat > "$top/SPECS/testall.spec" <<SPEC
Name: oxiguitar-testall
Version: 0.0.1
Release: 1
Summary: A made-up package for every architecture
License: GPL-3.0-or-later
BuildArch: noarch
%description
It tests this repository.
%global debug_package %{nil}
%install
install -D -m644 $tree/usr/share/oxiguitar-testall/hello %{buildroot}/usr/share/oxiguitar-testall/hello
%files
/usr/share/oxiguitar-testall/hello
SPEC
rpmbuild -bb --target noarch --define "_topdir $top" --define "_rpmdir $out/rpm" \
    --define "_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm" "$top/SPECS/testall.spec" > /dev/null
ls "$out/deb" "$out/rpm"
