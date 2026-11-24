# Testing

Every test of this repository runs with one command, on your own machine, and anyone can run it. When something fails, it tells you how to report it.

## Run everything

```sh
python3 scripts/test-all.py
```

On Windows, type `python` instead of `python3` if that's what you have.

You need:

- git, and Python 3.8 or newer (nothing to install with pip);
- for the shell lint stage: `bash`, `shellcheck`.
- for the release version bump stage: `bash`, `git`.
- for the release checks stage: `bash`, `sha256sum`.
- for the package site stage: `bash`, `gpg`, `dpkg-deb`, `apt-ftparchive`, `rpmbuild`, `createrepo_c`, `flatpak`, `ostree`.
- for the installing from the site stage: `bash`, `gpg`, `dpkg-deb`, `apt-ftparchive`, `rpmbuild`, `createrepo_c`, `flatpak`, `ostree`, `docker`.
- for the winget manifests stage: `bash`, `winget`.
- for the trial plugins stage: `bash`, `cargo`.
- for the trial plugins' tests stage: `cargo`.

It runs:

1. shellcheck on every shell script;
1. `scripts/release/bump.sh` on made-up repositories shaped like ours, and its refusals (`scripts/release/test-bump.sh`);
1. the Release workflow's wait for `ci-success`, against stand-ins for GitHub: a pass, a failure that passes when its failed jobs run again, one that stays red, no app key, a dry run, refused reruns (`tests/test-wait-for-ci.sh`);
1. `scripts/apt-install.sh` against a stand-in apt-get: a slow download let finish, a stuck one stopped and tried again on the next mirror, one that stays stuck, an apt error, `--recommends` (`tests/test-apt-install.sh`);
1. the checks a plugin release meets before it goes out, on made-up files: every file there and summed, no newer glibc than allowed (`tests/test-release-checks.sh`);
1. on Linux, test packages made and signed into an apt, dnf and Flatpak site with a throwaway key (`tests/test-site.sh`);
1. on Linux, the same site, then both test packages installed from it with apt and dnf in Debian and Fedora containers (`tests/test-site.sh --install`; needs docker, and pulls the two images);
1. on Windows, sample winget manifests made and validated by winget;
1. on Linux and Windows, the trial plugins built into `.oxp` files as a plugin repository builds them (`plugins/trial/build-oxp.sh`);
1. the trial plugins' own tests;
1. a check of the [Features](features.md) page: every feature names a test, and every test it names exists.

It tests the system and processor it runs on, and only those (as Rust sees them: `rustc -vV`'s host). Tests for other systems are left out and the summary says so; they are not failures.

Nothing is installed on this machine. The site stages need, on Debian and Ubuntu, `apt-utils createrepo-c rpm gnupg flatpak ostree appstream appstream-compose`; they sign with a throwaway key in a throwaway GnuPG home, so your own keys are never touched. Installing from the site happens in Debian and Fedora containers, with docker running; the stage is skipped otherwise. The trial plugins need the Rust named in `plugins/trial/Cargo.toml` (with `--ignore-rust-version`, an older one). On macOS the trial plugins are left out: their universal build needs both Rust targets, and plugin-release-try.yml builds it.

## What you get

A line per stage while it runs, then the result. In `target/test-all/<date>-<time>/`:

- `summary.md`: the result, your system, what failed and why, short enough to paste into a GitHub issue;
- `test-all.log`: everything that happened, every command and its output;

The script exits with 0 when everything passed, 1 when something failed, and 2 when it couldn't start.

## When something fails

1. Update to the newest `develop` (`git checkout develop && git pull`) and run it again: it may be fixed already.
2. Look for an issue about the same test at [github.com/mateusrdp/oxiguitar-packages/issues](https://github.com/mateusrdp/oxiguitar-packages/issues).
3. Otherwise [open one](https://github.com/mateusrdp/oxiguitar-packages/issues/new): call it `test-all: <the first failing test>`, paste the whole `summary.md`, and attach `test-all.log` (drag it onto the text box; zip it first if it's over 25 MB). Read the log first: it has your folder names, so change anything you'd rather keep private.
4. You can also give `summary.md` and `test-all.log` to a language model along with this repository and ask it to find the cause.

## Options

- `--release`: an optimised test build: slower to build, faster corpus tests.
- `--ignore-rust-version`: for a Rust older than `rust-version` (unsupported, but handy).
- `--out DIR`: where the results go.

## Adding a feature

A new feature comes with its tests and a row on the [Features](features.md) page, in the same pull request; a new corpus test uses `tests/support/corpus.rs`. The script fails until the row names tests that exist.
