# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- **oxiguitar-wav is now oxiguitar-export** (OxiGuitar #313): `repositories.txt`, the winget id (`mateusrdp.OxiGuitar.Export`, "Audio export"; never submitted), the CI's sample winget manifests, and the Flatpak names on the site and in the README. Until the renamed plugin's first release is published, the site keeps taking wav 0.1.2 through GitHub's redirect; from then on the repositories hold `oxiguitar-export` (`io.github.mateusrdp.OxiGuitar.Plugin.export`) and no longer `oxiguitar-wav`. The package doesn't replace the old one: users remove `oxiguitar-wav` by hand (OxiGuitar uses the new plugin either way, since its manifest replaces `oxiguitar.wav`).

### Added

- **oxiguitar-musicxml** in `repositories.txt` (OxiGuitar #223): the MusicXML plugin can be released with the Release button, and its `.deb` and `.rpm` join the apt and dnf repositories once its first release is published (until then the site skips it).
- **oxiguitar-tuxguitar** in `repositories.txt` (OxiGuitar #223, #171): the TuxGuitar plugin can be released with the Release button, its packages joining apt and dnf once its first release is published and this line has reached `main`.
- **oxiguitar-wah** in `repositories.txt` (OxiGuitar #250, #293): the wah-wah plugin can be released with the Release button (its first release, 0.1.0, needs OxiGuitar 0.20.0), its `.deb`, `.rpm` and Flatpak joining the repositories once that release is published and this line has reached `main`.

### Fixed

- **The Flatpak instructions** in the README and on the site add Flathub before this repository: `flatpak install` from this repository alone stops with "requires the runtime org.freedesktop.Platform … which was not found" where Flathub isn't set up (a `.flatpakrepo`, unlike the `.flatpakref`, can't name a runtime repository). They also list every plugin's Flatpak name, the plugins `oxiguitar` suggests now, and say that the sound-set package's question defaults to yes.
- **A release no longer stops half way when CI is slow**: the Release workflow made one GitHub App token at the start, which lasts an hour, and used it for the waits for CI and for every push; with macOS runners queuing, oxiguitar-midi-file's 0.1.1 run on 16 Nov 2026 pushed its release commit, then failed with `Bad credentials (HTTP 401)` before merging and tagging. The waits now read the public repository with the workflow's own token, the release commit and the merge and tag each get a fresh app token, and a run started again with the same version finds a release commit already on develop and finishes it (RELEASING.md, "When a run stops half way").
- **Dependabot's weekly Rust update** looks in `plugins/trial`, where the trial plugins' crates are; it looked for a `Cargo.toml` at the root, which has none, and failed every week.
