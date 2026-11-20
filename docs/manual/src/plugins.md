# The packages and their manuals

Each project has its own manual, and each manual covers only that project. The packages are named `oxiguitar-` plus the short name. The Flatpak extensions are `io.github.mateusrdp.OxiGuitar.Plugin.` plus the short name.

| Project | Package | Flatpak short name | What it does |
| --- | --- | --- | --- |
| [OxiGuitar](https://mateusrdp.github.io/oxiguitar/) | `oxiguitar` | (the app itself) | The program itself: opens, edits, shows and plays scores through plugins. |
| [Guitar Pro plugins](https://mateusrdp.github.io/oxiguitar-guitarpro/) | `oxiguitar-guitarpro` | `guitarpro` | Open Guitar Pro 3 to 8 files, and save .gp5 and .gp. |
| [MIDI plugin](https://mateusrdp.github.io/oxiguitar-midi/) | `oxiguitar-midi` | `midi` | Plays scores with SoundFont, DLS and SFZ sound sets. |
| [PipeWire output](https://mateusrdp.github.io/oxiguitar-pipewire/) | `oxiguitar-pipewire` | `pipewire` | Sends the sound to your speakers through PipeWire. |
| [ALSA output](https://mateusrdp.github.io/oxiguitar-alsa/) | `oxiguitar-alsa` | `alsa` | Sends the sound through ALSA, where PipeWire isn't running. |
| [NAM plugin](https://mateusrdp.github.io/oxiguitar-nam/) | `oxiguitar-nam` | `nam` | Amp models and cabinets on guitar and bass tracks. |
| [Equalizer plugin](https://mateusrdp.github.io/oxiguitar-eq/) | `oxiguitar-eq` | `eq` | A three-band or ten-band equalizer on any track. |
| [Wah-wah plugin](https://mateusrdp.github.io/oxiguitar-wah/) | `oxiguitar-wah` | `wah` | Writes and plays wah-wah marks. |
| [Temperament plugin](https://mateusrdp.github.io/oxiguitar-temperament/) | `oxiguitar-temperament` | `temperament` | Plays fretted tracks with a real guitar's tuning quirks. |
| [Audio clips plugin](https://mateusrdp.github.io/oxiguitar-clips/) | `oxiguitar-clips` | `clips` | Plays audio files along with the score. |
| [Audio export plugin](https://mateusrdp.github.io/oxiguitar-export/) | `oxiguitar-export` | `export` | Exports audio as WAV, FLAC, MP3 or Opus. |
| [MusicXML plugin](https://mateusrdp.github.io/oxiguitar-musicxml/) | `oxiguitar-musicxml` | `musicxml` | Opens and saves MusicXML. |
| [MIDI file plugin](https://mateusrdp.github.io/oxiguitar-midi-file/) | `oxiguitar-midi-file` | `midi-file` | Opens and saves Standard MIDI Files. |
| [TuxGuitar plugin](https://mateusrdp.github.io/oxiguitar-tuxguitar/) | `oxiguitar-tuxguitar` | `tuxguitar` | Opens and saves TuxGuitar 2 files. |
| [AI assistant plugin](https://mateusrdp.github.io/oxiguitar-ai/) | `oxiguitar-ai` | `ai` | A chat with a language model that reads and writes the score. |
| [Better sounds](https://mateusrdp.github.io/oxiguitar-bettersounds-soundfonts/) | `oxiguitar-bettersounds-soundfonts` | none | Downloads free recommended sound sets. |

Two plugins are not in these repositories because they exist only for one system. The [WASAPI output](https://mateusrdp.github.io/oxiguitar-wasapi/) is for Windows and the [Core Audio output](https://mateusrdp.github.io/oxiguitar-coreaudio/) is for macOS. Their installers are on their releases pages.
