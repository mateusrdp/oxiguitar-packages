# OxiGuitar packages

This is where OxiGuitar and its plugins are installed from on Linux. It serves three signed package repositories: apt for Debian and Ubuntu, dnf for Fedora, and Flatpak for any Linux distribution.

There is no program here, only the scripts that build the repositories. They take the packages from each project's latest published release, check them against the release's checksums, sign them with one key and publish them. Nothing is stored in this repository.

Windows and macOS have no package repository. Their installers are on each project's releases page, and the plugins' manuals say which file to take.
