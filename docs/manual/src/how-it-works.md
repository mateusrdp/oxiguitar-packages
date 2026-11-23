# Architecture and strategy

The site is built from scratch each time. Nothing from an earlier build is read.

1. A plugin's own publish workflow runs when its maintainer publishes a release. It checks that the release holds every file and checksum, then sends a `plugin-published` event to this repository.
2. The Site workflow starts. It downloads the `.deb`, `.rpm` and `.flatpak` files of the latest published release of every repository listed in `repositories.txt`, and checks each against the release's `SHA256SUMS`. A draft release is never taken.
3. It builds the apt repository with `apt-ftparchive`, the dnf repository with `createrepo_c`, and one OSTree repository for Flatpak, and signs all three with the same key.
4. It installs from the result as a test: a package with apt, and the app and every plugin from the Flatpak repository, opening a sample score in the sandbox.
5. It publishes the result on GitHub Pages, together with this manual.

Nothing polls. A repository is added to the site by adding its line to `repositories.txt`.

Every pull request builds a site from made-up packages with a throwaway key and installs from it with apt on Debian and dnf on Fedora, checking the signatures.

## Packaging for plugins

The plugins' release workflows call two reusable workflows from here, so a change to packaging never waits for an OxiGuitar release. `plugin-release.yml` builds a plugin for every system and makes the zips, the `.deb`, `.rpm`, Flatpak extension, Windows installer, macOS `.pkg` and checksums. `plugin-publish.yml` runs when the release is published and tells this site.

## Releasing

The maintainer makes a release with one button, Actions, Release, Run workflow, and then publishes the draft. `RELEASING.md` in this repository has the details.

## Current limitations

- **Linux only.** There is no winget (Windows) package yet, though the manifests are ready to go once a token for it exists; Homebrew was dropped. Windows and macOS users download installers from each release.
- **Not on Flathub.** OxiGuitar's Flatpaks come from our own repository, so they don't show up in a software centre until you add it.
- **Recent systems for `.deb` and `.rpm`.** They need glibc 2.39 or newer (Debian 13, Ubuntu 24.04, Fedora 40 and later). Older systems use the Flatpak or the AppImage.
- **One signing key for everything.** If it ever had to change, every user would need to fetch the new one.
- **Pre-releases.** Every package is still a pre-release until its v1.0.

## Left out on purpose

- **Flathub**, for now (Mateus, 9 November 2026): our own repository lets OxiGuitar and each plugin release on their own schedule, with the same signing as apt and dnf.
- **Homebrew** (dropped, 5 November 2026).
- **Paying for code signing** on Windows and Apple's notarisation. The installers work without it, with a warning the first time.
- **Keeping state.** The site is built from scratch from the latest published releases every time, so nothing drifts and nothing needs cleaning up.
- **Polling.** Nothing checks for new releases on a timer: a plugin's publish workflow tells this site when to build.

## Where you can help

- **Try the repositories on your distribution**, especially Fedora and ARM64 systems, and report what goes wrong.
- **Check the Flatpak** in GNOME Software or KDE Discover, and tell us how it looks and behaves.
- **Packaging know-how**: if you maintain packages for a distribution, a review of `scripts/plugin-package/` is welcome.

