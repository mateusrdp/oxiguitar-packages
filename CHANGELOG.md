# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed

- **A release no longer stops on a red `ci-success` that a rerun would fix** (oxiguitar 0.21.8, 24 Nov 2026: a slow Ubuntu mirror failed the NET-5 job, and its rerun passed). The Release workflow's waits for CI, on develop and on the release commit, now run the failed jobs again when `ci-success` fails, twice at most, and go on waiting (`scripts/release/wait-for-ci.sh`, tested by `tests/test-wait-for-ci.sh`). This needs the release App's **Actions: Read and write** permission: RELEASING.md, "When CI fails during a release".
- **A slow or stalled Ubuntu mirror no longer fails a job** (24 Nov 2026: the v0.21.8 packages' AppImage job failed three times on a 185 kB/s mirror although each try had downloaded more). CI, the Site workflow, the plugin release workflow and its trial install packages with `scripts/apt-install.sh` (the same file as OxiGuitar's). It watches the bytes in apt's download folders and stops apt only when they have not grown for 2 minutes (`APT_STALL_SECONDS`), then tries again on the next mirror, up to 5 times (`APT_TRIES`); while they grow, it lets apt finish however long that takes. It keeps what it downloaded and never stops dpkg half way. Its steps' timeouts are 60 minutes, as a last resort. Tested by `tests/test-apt-install.sh`.

- **Running Release again after a stopped run failed when anything had been merged into develop since** (oxiguitar-alsa 0.1.2, 23 Nov 2026: three Dependabot merges after `Release 0.1.2`, so the workflow tried to bump the same version again and `bump.sh` refused). It now finds the release commit anywhere since the latest tag, waits for that commit's CI and merges and tags exactly it.

### Changed

- RELEASING.md says how `oxiguitar-audio-cpal` is released (its tag is the release) and the order of an SDK or cpal bump: that repository first, then the four audio plugins, tags and `Cargo.lock` together.

### Added

- `oxiguitar-audio-cpal` in `other-repositories.txt`: the library the four audio output plugins share, moved out of OxiGuitar's repository (mateusrdp/oxiguitar#331), is released with the Release button like the plugins; its release is the tag.
- **Every test with one command** (mateusrdp/oxiguitar#273): `scripts/test-all.py` builds and runs all of this repository's tests, with a progress bar, a summary to paste into an issue and a log to diagnose from. The manual has a Features page naming the tests of every feature (CI checks it) and a Testing page.
- `tests/test-site.sh [--install]` does what CI's Repositories job does, on your machine, with nothing installed on it; `tests/test-release-checks.sh` tries `check-assets.sh` and `check-glibc.sh` on made-up files, in CI too.

### Fixed

- A plugin release with a dash in its version (`1.2.0-rc.1`) failed: bash 5.2 turned the `~` that `rpm.sh` and `check-assets.sh` put in place of the dash into the home folder's path.
- The trial plugins' `Cargo.lock` named SDK tag v0.19.1 while their `Cargo.toml` asks for v0.11.0, so `build-oxp.sh`'s `--locked` build refused to start; the lock now agrees.

### Changed

- **oxiguitar-wav is now oxiguitar-export** (OxiGuitar #313): `repositories.txt`, the winget id (`mateusrdp.OxiGuitar.Export`, "Audio export"; never submitted), the CI's sample winget manifests, and the Flatpak names on the site and in the README. Until the renamed plugin's first release is published, the site keeps taking wav 0.1.2 through GitHub's redirect; from then on the repositories hold `oxiguitar-export` (`io.github.mateusrdp.OxiGuitar.Plugin.export`) and no longer `oxiguitar-wav`. The package doesn't replace the old one: users remove `oxiguitar-wav` by hand (OxiGuitar uses the new plugin either way, since its manifest replaces `oxiguitar.wav`).
- **The manual explains the ideas behind the plugin** (its overview, with pictures), shows how to use it with screenshots, says in Architecture and strategy what it can't do yet, what is left out on purpose and where help is wanted, and has a Credits page listing every project it uses, with links and thanks. The README has a plain-words introduction and a Credits section.

### Added

- **oxiguitar-musicxml** in `repositories.txt` (OxiGuitar #223): the MusicXML plugin can be released with the Release button, and its `.deb` and `.rpm` join the apt and dnf repositories once its first release is published (until then the site skips it).
- **oxiguitar-tuxguitar** in `repositories.txt` (OxiGuitar #223, #171): the TuxGuitar plugin can be released with the Release button, its packages joining apt and dnf once its first release is published and this line has reached `main`.
- **oxiguitar-wah** in `repositories.txt` (OxiGuitar #250, #293): the wah-wah plugin can be released with the Release button (its first release, 0.1.0, needs OxiGuitar 0.20.0), its `.deb`, `.rpm` and Flatpak joining the repositories once that release is published and this line has reached `main`.

- **oxiguitar-temperament** in `repositories.txt` (OxiGuitar #294): the temperament plugin can be released with the Release button (its first release, 0.1.0, needs the OxiGuitar release with plugin interface 1.12), its `.deb`, `.rpm` and Flatpak (`io.github.mateusrdp.OxiGuitar.Plugin.temperament`) joining the repositories once that release is published and this line has reached `main`.

- **oxiguitar-ai** in `repositories.txt` (OxiGuitar #227): the AI plugin (a chat with a language model) can be released with the Release button (its first release, 0.1.0, needs the OxiGuitar release with plugin interface 1.14), its `.deb`, `.rpm` and Flatpak (`io.github.mateusrdp.OxiGuitar.Plugin.ai`) joining the repositories once that release is published and this line has reached `main`. Like clips and temperament, no package suggests it.
- **oxiguitar-clips** in `repositories.txt` (OxiGuitar #240): the audio-clips plugin can be released with the Release button (its first release, 0.1.0, needs the OxiGuitar release with plugin interface 1.13, 0.21.4), its `.deb`, `.rpm` and Flatpak (`io.github.mateusrdp.OxiGuitar.Plugin.clips`) joining the repositories once that release is published and this line has reached `main`.

### Fixed

- **The Flatpak instructions** in the README and on the site add Flathub before this repository: `flatpak install` from this repository alone stops with "requires the runtime org.freedesktop.Platform … which was not found" where Flathub isn't set up (a `.flatpakrepo`, unlike the `.flatpakref`, can't name a runtime repository). They also list every plugin's Flatpak name, the plugins `oxiguitar` suggests now, and say that the sound-set package's question defaults to yes.
- **A release no longer stops half way when CI is slow**: the Release workflow made one GitHub App token at the start, which lasts an hour, and used it for the waits for CI and for every push; with macOS runners queuing, oxiguitar-midi-file's 0.1.1 run on 16 Nov 2026 pushed its release commit, then failed with `Bad credentials (HTTP 401)` before merging and tagging. The waits now read the public repository with the workflow's own token, the release commit and the merge and tag each get a fresh app token, and a run started again with the same version finds a release commit already on develop and finishes it (RELEASING.md, "When a run stops half way").
- **Dependabot's weekly Rust update** looks in `plugins/trial`, where the trial plugins' crates are; it looked for a `Cargo.toml` at the root, which has none, and failed every week.

