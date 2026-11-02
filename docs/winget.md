# winget

Each plugin with a Windows installer has a winget package,
`mateusrdp.OxiGuitar.<Name>` (`GuitarPro`, `MIDI`, `WAV`, `WASAPI`, `NAM`),
installing its per-user setup program (Inno Setup, no administrator rights)
for x64 or arm64. Users run `winget install mateusrdp.OxiGuitar.MIDI`, and
`winget upgrade --all` keeps them current.

## The first submission of each package (by hand)

`wingetcreate update`, which the plugin repositories' publish workflow runs
for every later release, can only update a package that is in
[microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs) already. The
first version of each package is submitted by hand and reviewed at Microsoft
(usually within a few days). The manifests are made from the published
release, so do this after the release is published:

```sh
# once: your fork of winget-pkgs, and this repository
gh repo fork microsoft/winget-pkgs --clone=false
git clone --depth 1 https://github.com/mateusrdp/winget-pkgs
git clone --depth 1 https://github.com/mateusrdp/oxiguitar-packages

# for each package (here MIDI, version 0.1.0)
cd winget-pkgs
git switch -c mateusrdp.OxiGuitar.MIDI-0.1.0
../oxiguitar-packages/scripts/make-winget-manifests.sh \
    mateusrdp/oxiguitar-midi v0.1.0 manifests/m/mateusrdp/OxiGuitar/MIDI/0.1.0
git add manifests
git commit -m "New package: mateusrdp.OxiGuitar.MIDI version 0.1.0"
git push -u origin HEAD
gh pr create --repo microsoft/winget-pkgs --title "New package: mateusrdp.OxiGuitar.MIDI version 0.1.0" --body "A plugin for OxiGuitar, https://github.com/mateusrdp/oxiguitar-midi"
```

On Windows, `winget validate --manifest manifests/m/mateusrdp/OxiGuitar/MIDI/0.1.0`
checks the files first. NAM lists MIDI under `PackageDependencies`, so the
MIDI package must be accepted before NAM.

## Later releases

Set the secret `WINGET_TOKEN` in the plugin repository (a classic token with
`public_repo`; the fork above must exist). Publishing a release then opens the
pull request on winget-pkgs by itself. Until a package's first submission is
in, the "Submit to winget" job of that repository's Publish workflow fails
with "package not found"; the release and the other packages are unaffected.
