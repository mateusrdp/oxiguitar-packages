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
