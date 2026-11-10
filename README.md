# oxiguitar-packages

apt, dnf and Flatpak repositories for OxiGuitar and its plugins

Part of [OxiGuitar](https://github.com/mateusrdp/oxiguitar), a free, open-source
guitar tablature and score viewer, editor and player for Windows, macOS and
Linux. The user manual and the plugin developer guide live in the
[OxiGuitar repository](https://github.com/mateusrdp/oxiguitar).

## Using the repositories

The site is at <https://mateusrdp.github.io/oxiguitar-packages/>, which
repeats this section with the key's fingerprint.

Debian, Ubuntu and relatives:

```sh
sudo install -d -m 0755 /etc/apt/keyrings
sudo curl -fsSL https://mateusrdp.github.io/oxiguitar-packages/oxiguitar.gpg -o /etc/apt/keyrings/oxiguitar.gpg
sudo curl -fsSL https://mateusrdp.github.io/oxiguitar-packages/oxiguitar.sources -o /etc/apt/sources.list.d/oxiguitar.sources
sudo apt update
sudo apt install -o APT::Install-Suggests="true" oxiguitar
```

Fedora and relatives:

```sh
sudo curl -fsSL https://mateusrdp.github.io/oxiguitar-packages/oxiguitar.repo -o /etc/yum.repos.d/oxiguitar.repo
sudo dnf install oxiguitar
```

`oxiguitar` recommends the Guitar Pro, MIDI, ALSA and PipeWire plugins (apt installs recommended packages by default) and suggests `oxiguitar-nam` (amp models) and `oxiguitar-eq` (an equalizer); the option above installs the suggestions too. The MIDI plugin suggests `oxiguitar-bettersounds-soundfonts`, the recommended sound sets: installing it asks whether to download them now (about 1.2 GB; no is the default), and the command `oxiguitar-install-sounds` chooses and downloads them any time. It is the same package on every architecture.

Any Linux, as Flatpaks (the runtime comes from Flathub, which Flatpak adds if it isn't there):

```sh
flatpak remote-add --if-not-exists oxiguitar https://mateusrdp.github.io/oxiguitar-packages/flatpak/oxiguitar.flatpakrepo
flatpak install oxiguitar io.github.mateusrdp.OxiGuitar
flatpak install oxiguitar io.github.mateusrdp.OxiGuitar.Plugin.guitarpro io.github.mateusrdp.OxiGuitar.Plugin.midi io.github.mateusrdp.OxiGuitar.Plugin.pipewire
```

Each plugin is a Flatpak extension of the app, `io.github.mateusrdp.OxiGuitar.Plugin.NAME`; none comes with the app on its own. `flatpak/io.github.mateusrdp.OxiGuitar.flatpakref` on the site installs the app and adds both repositories in one step.

Plugins are the packages `oxiguitar-guitarpro`, `oxiguitar-midi`, `oxiguitar-nam`, and so on. The Windows-only (WASAPI) and macOS-only (CoreAudio) audio plugins are not in these repositories.

## Releasing

One button on GitHub, then publish the draft: see [RELEASING.md](RELEASING.md).

## Plugin packaging

The plugins' own release workflows call two reusable workflows from here, so
a change to the packaging never waits for an OxiGuitar release:

- [`plugin-release.yml`](.github/workflows/plugin-release.yml) builds a
  plugin's `.oxp` files for Linux (x86_64, ARM64), Windows (x86_64, ARM64)
  and macOS, and makes a zip per target, a `.deb` and `.rpm`
  (`oxiguitar-NAME`), a Flatpak extension of the OxiGuitar Flatpak
  (`io.github.mateusrdp.OxiGuitar.Plugin.NAME`, `scripts/plugin-package/flatpak.sh`), a per-user Windows installer, a macOS `.pkg` and
  `SHA256SUMS`, installs and removes each package on Debian, Fedora, Windows
  and macOS, and on a `v*` tag makes a draft release.
- [`plugin-publish.yml`](.github/workflows/plugin-publish.yml) runs when that
  draft is published: it checks the release holds every file and tells this
  repository (apt, dnf, Flatpak).

A plugin repository calls them `@main`:

```yaml
jobs:
  release:
    uses: mateusrdp/oxiguitar-packages/.github/workflows/plugin-release.yml@main
    with:
      name: midi
      title: "MIDI (SoundFont, SFZ)"
      description: "Plays scores with SoundFont, DLS and SFZ sound sets."
    permissions:
      contents: write
```

The scripts they run are in [`scripts/plugin-package/`](scripts/plugin-package).
Every pull request that touches them tries the whole release on the two
do-nothing plugins in [`plugins/trial/`](plugins/trial)
(`plugin-release-try.yml`), whose files stay under the run as test builds.
It also builds a Flatpak repository from their extensions, the released
Guitar Pro plugins' and OxiGuitar's latest Flatpak build, installs the app
and both plugins from it and opens a score in the sandbox.

## How it works

Nothing is stored here but the scripts. Each time the site is built
(`.github/workflows/site.yml`), `scripts/fetch-packages.sh` downloads the
`.deb`, `.rpm` and `.flatpak` files of the latest published release of every repository
in [`repositories.txt`](repositories.txt), checks each against the release's
`SHA256SUMS`, and `scripts/build-site.sh` makes the apt repository
(`apt-ftparchive`, `InRelease` and `Release.gpg`) and the dnf repository
(`createrepo_c`, signed packages and a signed `repomd.xml`), signs them with
one key; `scripts/flatpak-repo.sh` imports the Flatpak bundles into one
OSTree repository under `flatpak/`, signed with the same key, with
`oxiguitar.flatpakrepo` and `io.github.mateusrdp.OxiGuitar.flatpakref`
(whose `RuntimeRepo` is Flathub: the runtime is not mirrored), and
`scripts/test-flatpak.sh` installs the app and every plugin from it. The
result is deployed on GitHub Pages. A plugin repository's
publish workflow starts a build when its release is published; nothing polls.

Every pull request builds a site from made-up test packages with a throwaway
key and installs from it with apt (Debian) and dnf (Fedora), checking the
signatures (job "Repositories" in CI).

To add a plugin, add its repository to `repositories.txt`.

## winget

See [docs/winget.md](docs/winget.md): the manifests of a package's first
version are made by `scripts/make-winget-manifests.sh` and submitted by hand;
later versions are submitted by the plugin repository's publish workflow.

## The signing key

One RSA 4096 key signs both repositories. The maintainer makes it once and
keeps a copy offline:

```sh
gpg --quick-generate-key 'OxiGuitar packages <EMAIL>' rsa4096 sign never
gpg --armor --export-secret-keys FINGERPRINT   # the value of the secret below
```

and sets two secrets in this repository (Settings, Secrets and variables,
Actions): `APT_SIGNING_KEY`, the armoured private key, and
`APT_SIGNING_PASSPHRASE`, its passphrase (unset for a key without one). The
fingerprint is then written here:

> Fingerprint: `AFA3B6C603BCA98F123CA94848BDD452DF318B45`

The site is deployed from `main`, so the first build comes after `develop` is
merged into `main` (Actions, Site, Run workflow, branch `main`).

## Licence

GPL-3.0-or-later. See LICENSE.
Contributions are welcome under the same terms; see
[CONTRIBUTING.md](CONTRIBUTING.md).
