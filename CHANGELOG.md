# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **oxiguitar-musicxml** in `repositories.txt` (OxiGuitar #223): the MusicXML plugin can be released with the Release button, and its `.deb` and `.rpm` join the apt and dnf repositories once its first release is published (until then the site skips it).
- **oxiguitar-tuxguitar** in `repositories.txt` (OxiGuitar #223, #171): the TuxGuitar plugin can be released with the Release button, its packages joining apt and dnf once its first release is published and this line has reached `main`.
- **oxiguitar-wah** in `repositories.txt` (OxiGuitar #250, #293): the wah-wah plugin can be released with the Release button (its first release, 0.1.0, needs OxiGuitar 0.20.0), its `.deb`, `.rpm` and Flatpak joining the repositories once that release is published and this line has reached `main`.

### Fixed

- **Dependabot's weekly Rust update** looks in `plugins/trial`, where the trial plugins' crates are; it looked for a `Cargo.toml` at the root, which has none, and failed every week.
