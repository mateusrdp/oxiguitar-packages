# Requirements and assumptions

## Requirements

For the people using the repositories:

- Debian 13 or Ubuntu 24.04 or later, or Fedora 40 or later, for the `.deb` and `.rpm` packages. They need glibc 2.39 or newer. Older systems can use the Flatpak or the AppImage.
- For Flatpak, Flatpak itself, and Flathub for the runtime.
- Linux on x86_64 or ARM64.

For the people running the site:

- The secrets `APT_SIGNING_KEY` and `APT_SIGNING_PASSPHRASE`, which hold the signing key.
- A token, `PACKAGES_TOKEN`, in each plugin's repository, so its publish workflow can send the event.
- GitHub Pages, deployed from GitHub Actions, with `main` allowed to deploy.

## Assumptions

- Each plugin makes its releases with the shared workflows, so the files and checksums are where the site expects them.
- The site is deployed from `main`. A change on `develop` reaches the site after it is merged.
- Users trust one signing key for everything.
