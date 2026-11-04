# Releasing

Everything is done on github.com. A release is two clicks.

1. **Actions > Release > Run workflow** (in this repository). Pick the
   repository (`oxiguitar`, `oxiguitar-guitarpro`, ...; any in `repositories.txt` or
   `other-repositories.txt`, the second being the Windows-only and macOS-only
   plugins, which have no apt or dnf packages) and the version:
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
needs a release with it. Its packages are made by this repository's
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

## When a run stops half way

The steps are in order, so look at which one failed:

- **Before "Commit, merge into main, tag"**: nothing was pushed; fix what the
  message says and run again.
- **After the release commit reached `develop`** (the CHANGELOG no longer has
  an `[Unreleased]` entry): do not run the workflow again. Tag by hand on
  github.com: Releases, **Draft a new release**, create the tag `vX.Y.Z` on
  `main` after merging `develop` into `main` with a pull request, and carry on
  with step 2. Or ask Claude.
