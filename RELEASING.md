# Releasing

Everything is done on github.com. A release is two clicks.

1. **Actions > Release > Run workflow** (in this repository). Pick the
   repository (`oxiguitar`, `oxiguitar-guitarpro`, ...; any in `repositories.txt` or
   `other-repositories.txt`, the second being the Windows-only and macOS-only
   plugins, which have no apt or dnf packages, and `oxiguitar-audio-cpal`, a
   library the audio output plugins take by tag, which has no Release
   workflow of its own: its release is the tag) and the version:
   `patch`, `minor`, `major` (counted from its latest `v*` tag) or a number
   such as `0.13.0` (a repository's first release needs the number, and may
   keep the version it was made with, such as `0.1.0`). The workflow checks
   that `develop` is green, changes the files that name the version (it finds
   them in every plugin repository by itself; OxiGuitar has a
   `scripts/release/bump.sh` of its own for its extra ones) and moves the
   CHANGELOG's `[Unreleased]` section under the new version, commits that on `develop`, waits for CI,
   merges `develop` into `main` with a merge commit, tags that commit
   `vX.Y.Z` and pushes. The tag starts the repository's own Release
   workflow, which builds, tests and makes a **draft** release.
2. **Publish the draft** (the repository's Releases page) when its Release
   workflow is green. Publishing starts the Site workflow here, which
   rebuilds the signed apt and dnf repositories.

A plugin is released on its own: neither OxiGuitar nor any other plugin
needs a release with it. The exception is `oxiguitar-audio-cpal`, which the
four audio output plugins (alsa, pipewire, wasapi, coreaudio) take by tag
together with the SDK's tag and one cpal version. Its release is the tag:
there is no GitHub Release page, and nothing in this repository builds it. When
the SDK tag or cpal's version changes, release `oxiguitar-audio-cpal` first,
then change both tags in each of the four plugins in one pull request each and
refresh their `Cargo.lock` (`cargo update -p oxiguitar-audio-cpal -p cpal`);
the plugins' `deny.toml` must allow its git source. Plugins on different SDK
tags from the audio layer fail to build with two `Host` types. Its packages are made by this repository's
`plugin-release.yml` (`@main`), so a change to the packaging, once merged
into `main` here, is what the plugin's next release uses.

Tick "Only prepare the release" (dry run) first when in doubt: it shows what
would change and pushes nothing.

What goes into the release is what the CHANGELOG's `[Unreleased]` section
says, so write it as changes are merged. An empty `[Unreleased]` stops the
release.

## One-time setup

The workflow acts as a GitHub App, so no personal token is stored and it
works for every repository, including plugins not made yet.

### 1. Create the App

1. github.com, your profile picture, **Settings**, then **Developer settings**
   (bottom of the left menu), **GitHub Apps**, **New GitHub App**.
2. **GitHub App name**: `OxiGuitar Release` (if taken, add something, such as
   `OxiGuitar Release mateusrdp`). **Homepage URL**:
   `https://github.com/mateusrdp/oxiguitar-packages`.
3. **Webhook**: untick **Active**. Leave the callback URL empty and
   "Request user authorization" unticked.
4. **Repository permissions** (nothing else):
   - **Contents**: Read and write
   - **Workflows**: Read and write (a merge into `main` may carry workflow files)
   - **Checks**: Read-only (to see that CI passed)
   - **Actions**: Read and write (to run CI's failed jobs again during a
     release; see "When CI fails during a release")
   - **Metadata**: Read-only (set by GitHub)
5. **Where can this GitHub App be installed?**: Only on this account.
6. **Create GitHub App**. On the page that follows, copy the **App ID**.
7. Scroll to **Private keys**, **Generate a private key**: a `.pem` file is
   downloaded.
8. In the left menu, **Install App**, **Install** next to your account, choose
   **All repositories** (so plugin repositories made later are covered), **Install**.

### 2. Give the key to this repository

In **oxiguitar-packages**, Settings, **Secrets and variables**, **Actions**:

- **Variables** tab, **New repository variable**: name `RELEASE_APP_ID`, value the App ID.
- **Secrets** tab, **New repository secret**: name `RELEASE_APP_KEY`, value the
  whole text of the `.pem` file, the `-----BEGIN` and `-----END` lines included.

Then keep the `.pem` in your password manager and delete it from Downloads.

### 3. Let the App past the branch rules

The App has to push to `develop` and `main` and create `v*` tags without pull
requests. For each repository that is released (`oxiguitar` and every plugin):

1. Settings, **Rules**, **Rulesets**; open each ruleset that covers `develop`
   or `main` (and the one for `v*` tags, if there is one).
2. **Bypass list**, **Add bypass**, tick **OxiGuitar Release** (under Apps),
   mode **Always allow**, **Save changes**.
   (With classic branch protection instead: Settings, **Branches**, edit the
   rule, and add the App under "Allow specified actors to bypass required
   pull requests" and under the push restrictions, if ticked.)

Every repository made with OxiGuitar's `scripts/new-repo.sh` (which you run
to create one) gets the bypass from the start, so this is only for a
repository made before the App existed. As of 3 Nov 2026 every released
repository has it except `oxiguitar-bettersounds-soundfonts`.

### 4. Try it

Run **Release** with repository `oxiguitar`, version `patch` and **dry run**
ticked. The run's summary shows the files it would change. Then run it for real.

## When CI fails during a release

Most red `ci-success` checks during a release were not the code: a slow
Ubuntu mirror, a macOS runner cancelled before it started, a 503 from
GitHub. So when `ci-success` fails on develop or on the release commit, the
run starts the failed jobs of that CI run again and goes on waiting, twice
at most (`scripts/release/wait-for-ci.sh`); the run's log says
"running the failed jobs of ... again" with the link. A real failure fails
every time and the release stops as before.

This needs the App's **Actions: Read and write** permission. For an App made
before 24 Nov 2026:

1. github.com, **Settings**, **Developer settings**, **GitHub Apps**,
   **OxiGuitar Release**, **Edit**, **Permissions & events**.
2. **Repository permissions**, **Actions**: **Read and write**. **Save changes**.
3. GitHub then asks the installation to accept it: **Settings**,
   **Applications**, **Installed GitHub Apps**, **OxiGuitar Release**,
   **Configure**, **Review request**, **Accept new permissions**.

Without it the run says "no token to run the jobs again" and stops at the
first failure, as it did before.

## When a run stops half way

The steps are in order, so look at which one failed:

- **Before "Commit the release on develop"**: nothing was pushed; fix what
  the message says and run again.
- **After the release commit reached `develop`** (`Release X.Y.Z` is on
  develop; a token that expired while CI waited, CI that took longer than two
  hours, or a runner that timed out): run **Release** again with the **same
  version** (`X.Y.Z`, or `patch` if no tag was made since). It finds the
  release commit among develop's commits since the latest tag, bumps nothing,
  waits for that commit's CI and merges it, tags and pushes as usual. Commits
  merged into develop after it (Dependabot's, say) are not part of the
  release: they stay on develop for the next one. (Before 23 Nov 2026 the
  release commit had to be develop's last, and a Dependabot merge in between
  failed the run with "X.Y.Z is not higher than the current version": then
  merge the release commit, not develop, into `main` by hand and tag it.)

The app's tokens last an hour. The waits for CI read the repository with
this workflow's own token, and each push gets a token made just before it,
so a slow CI (macOS runners can queue for over an hour) no longer stops a
run half way.
