# Installing from the repositories

## Debian, Ubuntu and relatives

Add the repository once, like a PPA:

```sh
sudo install -d -m 0755 /etc/apt/keyrings
sudo curl -fsSL https://mateusrdp.github.io/oxiguitar-packages/oxiguitar.gpg -o /etc/apt/keyrings/oxiguitar.gpg
sudo curl -fsSL https://mateusrdp.github.io/oxiguitar-packages/oxiguitar.sources -o /etc/apt/sources.list.d/oxiguitar.sources
sudo apt update
sudo apt install -o APT::Install-Suggests="true" oxiguitar
```

`oxiguitar` recommends the Guitar Pro, MIDI, ALSA and PipeWire plugins, and apt installs recommended packages by default. It suggests the NAM, equalizer and wah plugins and the MusicXML, MIDI file and TuxGuitar plugins, and the option above installs those too. Add any other plugin by name, for example `sudo apt install oxiguitar-clips`. `sudo apt upgrade` keeps everything current.

## Fedora and relatives

```sh
sudo curl -fsSL https://mateusrdp.github.io/oxiguitar-packages/oxiguitar.repo -o /etc/yum.repos.d/oxiguitar.repo
sudo dnf install oxiguitar
```

dnf installs the recommended plugins with it, and `sudo dnf upgrade` keeps them current.

## Flatpak, any Linux

Flatpak takes its runtime from Flathub and everything else from this repository, so add both:

```sh
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists oxiguitar https://mateusrdp.github.io/oxiguitar-packages/flatpak/oxiguitar.flatpakrepo
flatpak install oxiguitar io.github.mateusrdp.OxiGuitar
flatpak install oxiguitar io.github.mateusrdp.OxiGuitar.Plugin.guitarpro io.github.mateusrdp.OxiGuitar.Plugin.midi io.github.mateusrdp.OxiGuitar.Plugin.pipewire
```

Many systems have Flathub already, and the first line then changes nothing. Without Flathub, `flatpak install` stops with a message that it requires the runtime `org.freedesktop.Platform`. The file `flatpak/io.github.mateusrdp.OxiGuitar.flatpakref` on this site does the first three steps in one and adds both repositories. Add `--user` to install for yourself only.

Each plugin is a Flatpak extension named `io.github.mateusrdp.OxiGuitar.Plugin.` plus its short name. None comes with the app on its own, so take at least a format plugin such as `guitarpro`, `midi` and an audio output (`pipewire` on most desktops, `alsa` otherwise).

The Flatpak runs in a sandbox. It opens and saves the files you choose in its file dialogs and sees nothing else, so it has folders of its own:

| Folder | What goes in it |
| --- | --- |
| `~/.var/app/io.github.mateusrdp.OxiGuitar/data/oxiguitar/plugins/` | Plugin files (`.oxp`) that aren't Flatpak packages |
| `~/.var/app/io.github.mateusrdp.OxiGuitar/data/oxiguitar/soundfonts/` | Sound sets |
| `~/.var/app/io.github.mateusrdp.OxiGuitar/data/oxiguitar/nam/` | Amp models and cabinets |

The sandbox doesn't see your system's sound sets either, so the Flatpak plays nothing until it has one. The sound set installer fills the Flatpak's folder when the Flatpak is installed.

## Sound sets

`oxiguitar-midi` suggests the package `oxiguitar-bettersounds-soundfonts`, which downloads a free recommended collection of sound sets, about 1.2 GB. On Debian and Ubuntu it asks first, and yes is the default. On Fedora it just does. If you say no, or a download fails, `sudo oxiguitar-install-sounds --system` chooses and downloads them later. OxiGuitar itself never downloads anything.

## Checking the key

One RSA 4096 key signs the apt, dnf and Flatpak repositories. Its fingerprint is `AFA3B6C603BCA98F123CA94848BDD452DF318B45`.
