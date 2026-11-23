# OxiGuitar packages

This is where OxiGuitar and its plugins are installed from on Linux. It serves three signed package repositories: apt for Debian and Ubuntu, dnf for Fedora, and Flatpak for any Linux distribution.

There is no program here, only the scripts that build the repositories. They take the packages from each project's latest published release, check them against the release's checksums, sign them with one key and publish them. Nothing is stored in this repository.

Windows and macOS have no package repository. Their installers are on each project's releases page, and the plugins' manuals say which file to take.

## Package repositories, in plain words

On Linux, programs are usually installed by a **package manager**: `apt` on Debian and Ubuntu, `dnf` on Fedora, and the app stores (GNOME Software, KDE Discover) built on them. A package manager installs from **repositories**, web sites laid out the way it expects, listing every package with its version and what it needs. Add a repository once, and from then on your normal system updates keep everything from it up to date. That is what this project gives OxiGuitar: you add it once ([Installing from the repositories](use-cases.md)), and OxiGuitar and every plugin you chose update along with the rest of your system.

**Signing** is how you know a package really came from us. Every repository here is signed with one key, whose public half you download when you add the repository. Your package manager then refuses any package that doesn't match the signature, whoever served it.

**Flatpak** is a different way to install programs, the same on every Linux distribution. A Flatpak app brings its own libraries (a *runtime*, shared between apps) and runs in a *sandbox* that only sees the folders it is allowed to. OxiGuitar's plugins are Flatpak *extensions* of the app, installed next to it. Flathub is the best-known Flatpak repository; OxiGuitar has its own instead, and takes only the runtime from Flathub.

Windows and macOS have no package repository here: their installers are on each project's releases page, and each plugin's manual says which file to take.

