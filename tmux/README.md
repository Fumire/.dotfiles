# tmux Configuration

tmux configuration for this dotfiles repository. The main `tmux.conf` is based on [gpakosz/.tmux](https://github.com/gpakosz/.tmux), with personal overrides in `tmux.conf.local`.

## Files

| File | Purpose |
| --- | --- |
| `Makefile` | Installs both config files under the home directory. |
| `tmux.conf` | Main tmux configuration, key bindings, helper functions, and theme engine. |
| `tmux.conf.local` | Local overrides for prompt/status styling, mouse behavior, prefix key, clipboard integration, and plugins. |

## Installation

From the repository root:

```sh
make tmux_run
```

Or from this directory:

```sh
make
```

This creates:

* `tmux/tmux.conf` -> `~/.tmux.conf`
* `tmux/tmux.conf.local` -> `~/.tmux.conf.local`

If a destination file already exists and is not a symlink, the Makefile backs it up before linking.

## Main Behavior

The main config sets up:

* `tmux-256color` when available, otherwise `screen-256color`
* GNU Screen-compatible secondary prefix support in the base config
* faster escape handling and longer repeat timeouts
* focus events
* 5,000 lines of scrollback history
* windows and pane indexes starting at `1`
* automatic window renaming
* automatic window renumbering after closing windows
* terminal title updates
* activity monitoring without visual activity popups
* vi-style copy-mode bindings
* copy integration with X11, macOS, Windows, or Cygwin clipboards when the required tools are available
* a reload binding for `~/.tmux.conf`
* a binding to edit `~/.tmux.conf.local`

## Key Bindings

The local config changes the primary prefix to `C-a`.

Common bindings:

| Binding | Action |
| --- | --- |
| `C-a r` | Reload `~/.tmux.conf`. |
| `C-a e` | Edit `~/.tmux.conf.local` in `$EDITOR`, then reload. |
| `C-a C-c` | Create a new session. |
| `C-a C-f` | Find and switch sessions. |
| `C-a BTab` | Switch to the last session. |
| `C-a -` | Split the current window vertically. |
| `C-a _` | Split the current window horizontally. |
| `C-a h/j/k/l` | Move between panes. |
| `C-a H/J/K/L` | Resize panes. |
| `C-a >/ <` | Swap the current pane with the next or previous pane. |
| `C-a +` | Toggle pane maximization. |
| `C-a C-h` | Previous window. |
| `C-a C-l` | Next window. |
| `C-a Tab` | Last active window. |
| `C-a m` | Toggle mouse mode. |
| `C-a Enter` | Enter copy mode. |
| `C-a b` | List paste buffers. |
| `C-a p` | Paste the top paste buffer. |
| `C-a P` | Choose a paste buffer. |
| `C-a U` | Open detected URLs with urlview helper. |
| `C-a F` | Run the Facebook PathPicker helper. |

## Local Overrides

`tmux.conf.local` customizes the base config:

* New windows and panes retain the current working directory.
* New panes do not try to reconnect SSH sessions.
* Mouse mode starts enabled.
* The active prefix is `C-a`; the default `C-b` binding is removed.
* Copying from copy mode also copies to the OS clipboard when possible.
* Status colors, separators, pane borders, window status formats, battery symbols, and clock style are customized.
* The status left side shows session name, uptime, load average, and online status.
* The status right side is overridden to show CPU status and date/time.

## Plugins

The local config enables tmux plugin manager integration from the gpakosz base config and lists these plugins:

| Plugin | Purpose |
| --- | --- |
| `tmux-plugins/tmux-cpu` | Adds CPU information to the status line. |
| `tmux-plugins/tmux-resurrect` | Saves and restores tmux sessions. |
| `tmux-plugins/tmux-continuum` | Automatically restores sessions. |

Plugin behavior:

* Plugins update on tmux launch.
* Plugins update on config reload.
* `tmux-resurrect` save key is `S`.
* `tmux-resurrect` restore key is `R`.
* Pane contents are included in resurrect captures.
* Continuum restore is enabled.

## Clipboard Dependencies

Clipboard copying works when one of these tools is available:

* macOS: `pbcopy`
* macOS tmux integration: `reattach-to-user-namespace`
* Linux/X11: `xsel` or `xclip`
* Windows: `clip.exe`
* Cygwin: `/dev/clipboard`

## Notes

`tmux.conf` includes a comment that it should not be edited directly. Put personal changes in `~/.tmux.conf.local`, which is linked from `tmux/tmux.conf.local` by this repository.

Powerline-style separators are used in the status line. Use a font with Powerline symbols if separators do not render correctly.
