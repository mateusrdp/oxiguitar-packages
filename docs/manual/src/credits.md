# Credits

This project is mostly glue between excellent tools other people wrote. Thank you to all of them.

## Tools that build the repositories

| Tool | Use |
| --- | --- |
| [APT](https://salsa.debian.org/apt-team/apt)'s `apt-ftparchive` | Builds the apt repository |
| [dpkg](https://salsa.debian.org/dpkg-team/dpkg)'s `dpkg-deb` | Builds the `.deb` packages |
| [RPM](https://rpm.org/)'s `rpmbuild` | Builds the `.rpm` packages |
| [createrepo_c](https://github.com/rpm-software-management/createrepo_c) | Builds the dnf repository |
| [Flatpak](https://flatpak.org/) and [OSTree](https://github.com/ostreedev/ostree) | Build the Flatpak app, its extensions and the Flatpak repository |
| [AppStream](https://www.freedesktop.org/wiki/Distributions/AppStream/)'s `appstreamcli` | Checks the metadata software centres show |
| [GnuPG](https://gnupg.org/) | Signs everything |
| [Inno Setup](https://jrsoftware.org/isinfo.php) | Builds the plugins' Windows installers |
| Apple's `pkgbuild` and `productbuild` | Build the plugins' macOS installers |
| [Flathub](https://flathub.org/) | Hosts the Freedesktop runtime the Flatpaks run on |
| [GitHub Actions](https://github.com/features/actions) and [GitHub Pages](https://pages.github.com/) | Run the workflows and serve the repositories |
| [mdBook](https://github.com/rust-lang/mdBook) | Builds this manual |
| [Bash](https://www.gnu.org/software/bash/) and [Python](https://www.python.org/) | The scripts |

## Thanks

To the Debian, Fedora, Flatpak and Freedesktop communities, whose packaging tools and runtimes let a small project ship to every Linux distribution, and to everyone who adds our repository and tells us how it went.
