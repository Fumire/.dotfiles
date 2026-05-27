# macOS Setup

macOS-specific setup files for this dotfiles repository. This folder mainly manages Homebrew packages, macOS defaults, Mackup storage, LanguageTool settings, and a few local service/config files.

## Files

| File | Purpose |
| --- | --- |
| `Makefile` | Provides targets for Homebrew bundle installation, macOS defaults, and selected config symlinks. |
| `Brewfile.free` | Core Homebrew profile used by the top-level `make mac_run` target. |
| `Brewfile` | Broader Homebrew profile with additional apps and services. |
| `Brewfile.Mac` | Extended Mac profile with extra development tools, casks, Mac App Store apps, VS Code extensions, and taps. |
| `starting.sh` | Applies macOS defaults for Finder, Dock, Safari, Terminal, screenshots, keyboard, trackpad, security, date/time, and related settings. |
| `mackup.cfg` | Mackup configuration using Dropbox storage while ignoring dotfiles already managed by this repository. |
| `languageserver.properties` | LanguageTool language server settings. |
| `languagetool.cfg` | LanguageTool application configuration. |
| `cloudflared.yml` | Cloudflare DNS-over-HTTPS proxy configuration. |
| `screenrc` | GNU Screen configuration. |

## Requirements

* macOS
* Homebrew
* `make`
* Mac App Store login before installing `mas` applications
* Administrator access for settings that require `sudo`

## Installation

From the repository root, install the default free macOS package set:

```sh
make mac_run
```

This runs:

```sh
make -C mac free
```

The `free` target installs and verifies `Brewfile.free` with:

```sh
brew bundle --file=mac/Brewfile.free --verbose
brew bundle check --file=mac/Brewfile.free --verbose
```

## Other Homebrew Profiles

Install the broader `Brewfile` profile:

```sh
make -C mac bundle
```

Install the extended `Brewfile.Mac` profile manually:

```sh
brew bundle --file=mac/Brewfile.Mac --verbose
brew bundle check --file=mac/Brewfile.Mac --verbose
```

Use one Homebrew profile at a time unless you intentionally want the union of all listed packages and applications.

## macOS Defaults

Apply macOS defaults with:

```sh
make -C mac start
```

This runs `starting.sh`. It changes Finder, Dock, Safari, Terminal, screenshot, keyboard, trackpad, date/time, security, and related system preferences. It also runs `xcode-select --install`, uses `sudo` for some system settings, and restarts affected applications at the end.

Review `starting.sh` before running it on a machine that already has customized macOS preferences.

## Config Symlinks

Create the Mackup config symlink:

```sh
make -C mac "$HOME/.mackup.cfg"
```

Create the LanguageTool language server config symlink:

```sh
make -C mac "$HOME/.languagetool.cfg"
```

The LanguageTool target links `languageserver.properties` to `~/.languagetool.cfg`.

## Notes

The Makefile includes a `brew` target for installing Homebrew, but the package targets assume Homebrew is already available. Install Homebrew first, then run the bundle targets.

Several files in this folder are personal-machine specific. Check paths, app lists, Mac App Store IDs, and service configuration before using them on another machine.
