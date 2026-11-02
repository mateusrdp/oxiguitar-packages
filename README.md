# oxiguitar-packages

apt and dnf repositories for OxiGuitar and its plugins

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
sudo apt install oxiguitar
```

Fedora and relatives:

```sh
sudo curl -fsSL https://mateusrdp.github.io/oxiguitar-packages/oxiguitar.repo -o /etc/yum.repos.d/oxiguitar.repo
sudo dnf install oxiguitar
```

Plugins are the packages `oxiguitar-guitarpro`, `oxiguitar-midi`, `oxiguitar-nam`, and so on. The Windows-only (WASAPI) and macOS-only (CoreAudio) audio plugins are not in these repositories.

## How it works

Nothing is stored here but the scripts. Each time the site is built
(`.github/workflows/site.yml`), `scripts/fetch-packages.sh` downloads the
`.deb` and `.rpm` files of the latest published release of every repository
in [`repositories.txt`](repositories.txt), checks each against the release's
`SHA256SUMS`, and `scripts/build-site.sh` makes the apt repository
(`apt-ftparchive`, `InRelease` and `Release.gpg`) and the dnf repository
(`createrepo_c`, signed packages and a signed `repomd.xml`), signs them with
one key, and the result is deployed on GitHub Pages. A plugin repository's
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

> Fingerprint: _not set yet_

The site is deployed from `main`, so the first build comes after `develop` is
merged into `main` (Actions, Site, Run workflow, branch `main`).

## Licence

GPL-3.0-or-later. See LICENSE.
Contributions are welcome under the same terms; see
[CONTRIBUTING.md](CONTRIBUTING.md).
