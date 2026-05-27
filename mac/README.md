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

### `starting.sh` Settings

The `starting.sh` script applies these macOS settings:

| Area | Setting |
| --- | --- |
| Developer tools | Runs `xcode-select --install` to install Apple command line developer tools. |
| Quick Look | Enables text selection in Quick Look previews. |
| Printing | Quits the printer app automatically after print jobs complete. |
| Software Update | Checks for software updates daily instead of weekly. |
| Finder | Shows all filename extensions. |
| Finder | Sets the preferred Finder view style to the configured `FXPreferredViewStyle` value. |
| Finder | Prevents `.DS_Store` files on network and USB volumes. |
| Finder | Hides Desktop icons by setting `CreateDesktop` to `false`. |
| Finder | Shows hidden files by default. |
| Finder | Shows the status bar and path bar. |
| Finder | Keeps folders on top when sorting by name. |
| Terminal | Restricts Terminal string encodings to UTF-8. |
| Terminal | Uses the Pro profile for default and startup windows. |
| Screenshots | Saves screenshots to `~/Desktop`. |
| Screenshots | Saves screenshots as PNG files. |
| Safari | Enables the internal debug menu. |
| Safari | Enables the Develop menu and Web Inspector. |
| Transmission | Disables the confirmation prompt before downloading. |
| Time and locale | Uses 24-hour time. |
| Time and locale | Sets custom date format strings. The script writes date format key `2` twice, so the later value is the one macOS keeps for that key. |
| Time and locale | Enables automatic timezone detection and network time using `sudo`. |
| Sound | Sets the alert sound to `Submarine.aiff`. |
| Sound | Disables audio feedback when changing volume. |
| Dock | Sets Dock tile size to `16`. |
| Dock | Disables all four hot corners. |
| Dock | Hides recently used applications from the Dock. |
| System behavior | Enables automatic restart when the computer freezes. |
| Security | Disables the quarantine prompt for opening downloaded applications. Review this before use on a security-sensitive machine. |
| Security | Requires a password immediately after sleep or screen saver starts. |
| Keyboard | Sets a fast key repeat rate and short initial repeat delay. |
| Keyboard | Disables automatic spelling correction. |
| Keyboard backlight | Enables automatic keyboard illumination in low light. |
| Keyboard backlight | Turns off keyboard illumination after 5 minutes of inactivity. |
| Trackpad | Enables tap-to-click for the current user and login screen. |
| Trackpad | Enables three-finger swipe navigation between pages. |
| Bluetooth audio | Raises the editable Bluetooth audio bitpool minimum to improve headset audio quality. |
| Calendar | Shows week numbers. |
| Calendar | Sets Monday as the first day of the week. |
| App restart | Restarts affected apps such as Dock, Finder, Safari, Mail, Calendar, Contacts, and SystemUIServer so settings take effect. |

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
