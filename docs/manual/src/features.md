# Features and their tests

Every feature of this repository and the tests that check it. This
repository has no Rust code of its own (the trial plugins aside): its tests
are the stages of `tests/suite.json`, named here as `stage:NAME`.
`python3 scripts/test-all.py` runs every stage your system can run and
checks that each row names a stage that exists. A new feature comes with its
tests and a row here, in the same pull request.

Some features run only on GitHub (publishing the site, a real plugin
release); their tests try the same scripts on made-up packages and files.

## The package repositories

| Feature | Tests |
| --- | --- |
| An apt repository, a dnf repository and a Flatpak repository built from scratch from the packages given, all signed with one key (`scripts/build-site.sh`) | `linux:stage:package site` |
| The Flatpak repository carries each plugin's extension, a signed summary and a `.flatpakrepo` with the key; no `.flatpakref` without an OxiGuitar bundle | `linux:stage:package site` |
| A package for one processor and one for every processor, both installed with apt on Debian and dnf on Fedora, signatures checked (`scripts/test-install.sh`) | `linux:stage:installing from the site` |
| Test packages made with the plugins' own packaging scripts, so the site needs no release (`scripts/make-test-packages.sh`) | `linux:stage:package site` |

## Packaging for plugins

| Feature | Tests |
| --- | --- |
| A plugin built into an `.oxp` file for the system it runs on, as `plugin-release.yml` builds it | `linux,windows:stage:trial plugins`, `stage:trial plugins' tests` |
| A release is checked before it goes out: every zip, `.deb`, `.rpm`, Flatpak, setup `.exe` and `.pkg` there and in SHA256SUMS, with the right sums; a plugin for some systems only says which (`scripts/plugin-package/check-assets.sh`) | `stage:release checks` |
| A pre-release version (`1.2.0-rc.1`) becomes `1.2.0~rc.1` in the `.rpm`'s name | `stage:release checks` |
| No ELF file of a plugin, nor the library inside a plugin file (a tar archive), needs a newer glibc than allowed (`scripts/plugin-package/check-glibc.sh`) | `stage:release checks` |
| Winget manifests for a plugin release, valid for winget (`scripts/make-winget-manifests.sh`) | `windows:stage:winget manifests` |

## Releases

| Feature | Tests |
| --- | --- |
| A release's version bumped in one step in a single plugin, a workspace of plugins and a repository with a VERSION file, and the refusals (`scripts/release/bump.sh`) | `stage:release version bump` |
| A release waits for `ci-success` and runs the failed jobs again (twice at most) when it fails, so a slow mirror or a cancelled runner does not stop it (`scripts/release/wait-for-ci.sh`) | `stage:release wait for CI` |
| Packages on GitHub's Ubuntu runners are installed through a slow mirror however long it takes, and apt is stopped and tried again on the next mirror only when its downloads stop growing (`scripts/apt-install.sh`) | `stage:apt install` |
| Every shell script passes shellcheck | `stage:shell lint` |
