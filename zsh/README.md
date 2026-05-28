# ZSH

ZSH configuration files for this dotfiles repository.

## Files

| File | Purpose |
| --- | --- |
| `zshenv` | Sources `~/.zshrc` for login shells when the file exists. |
| `zshrc` | Main interactive ZSH configuration. |
| `alias.zsh` | Shell aliases and helper functions loaded by `zshrc`. |
| `zlogout` | Optional logout hook that prints a random quote. |
| `Makefile` | Installs config files as symlinks and backs up existing non-symlink destinations. |
| `zsh.bash` | Older Bash-based installer script; the Makefile is the preferred install path. |

## Settings

The main settings are in `zshrc`:

| Setting | Explanation |
| --- | --- |
| `stty -ixon` | Disables terminal flow control so `Ctrl-s` and `Ctrl-q` are not intercepted by the terminal. |
| SSH-aware theme selection | Uses the `remote` oh-my-zsh theme when `$SSH_CONNECTION` is set and `local` otherwise. |
| `zstyle ':omz:alpha:lib:git' async-prompt no` | Disables oh-my-zsh asynchronous Git prompt behavior. |
| oh-my-zsh loading | Loads `${ZDOTDIR:-$HOME}/.oh-my-zsh/oh-my-zsh.sh` when oh-my-zsh is installed. |
| Plugins | Enables `git`, `vi-mode`, `zsh-syntax-highlighting`, and `ssh-agent`. |
| Editor selection | Uses `nvim` for `EDITOR` and `VISUAL` on macOS, and `vim` elsewhere. |
| Homebrew PATH | Adds `/opt/homebrew/bin` and `/opt/homebrew/sbin` on macOS. |
| Pager | Sets `PAGER` to `less`. |
| Terminal fallback | Sets `TERM=xterm-256color` if `TERM` is empty. |
| SSH key path | Sets `SSH_KEY_PATH` to `~/.ssh/id_rsa` when that key exists. |
| ssh-agent plugin | Configures the oh-my-zsh `ssh-agent` plugin to load `id_rsa` and keep it for 12 hours. |
| Locale | Defaults `LC_ALL` and `LANG` to `en_US.UTF-8` if they are unset. |
| Alias loading | Sources `~/.alias.zsh` when it exists. |
| Command-line editor | Enables `edit-command-line` and binds it to `Ctrl-x e` and `Ctrl-x Ctrl-e`. |
| PATH additions | Prepends `/usr/local/sbin`, `~/.local/bin`, and `~/go/bin`. |
| GPG terminal | Sets `GPG_TTY` to the current terminal for GPG passphrase prompts. |
| Slurm format | Defines `SQUEUE_FORMAT` for compact `squeue` output. |
| Java/X11 rendering | Sets `_JAVA_OPTIONS` and `JAVA_OPTIONS` for Java font antialiasing and XRender behavior. |
| Virtualenv prompt | Sets `VIRTUAL_ENV_DISABLE_PROMPT` so the custom shell theme controls virtualenv display. |
| Git prompt helper | Defines `__git_prompt_git` to run Git prompt commands with `GIT_OPTIONAL_LOCKS=0` and a 1-second timeout. |
| `uuid` function | Generates a random UUID-like identifier for helper scripts and background logs. |

## Aliases and Functions

`alias.zsh` defines these shortcuts:

| Name | Type | Explanation |
| --- | --- | --- |
| `rm` | Alias | Runs `rm -i` to ask before removing files. |
| `mv` | Alias | Runs `mv -i` to ask before overwriting files. |
| `cp` | Alias | Runs `cp -i` to ask before overwriting files. |
| `py` | Alias | Runs `python3`. |
| `pipUpdate` | Alias | Updates locally installed pip packages, excluding editable installs and direct URL/path packages. |
| `yt-dlp` | macOS alias | Runs `python3 -m yt_dlp` on macOS. |
| `vim` | macOS alias | Runs `nvim` on macOS. |
| `vi` | macOS alias | Runs `nvim` on macOS. |
| `vimdiff` | macOS alias | Runs `nvim -d` on macOS. |
| `copyssh` | macOS alias | Copies `~/.ssh/id_rsa.pub` to the macOS clipboard with `pbcopy`. |
| `weather` | Function | Fetches weather from `wttr.in`; defaults to Seoul and uses metric units. |
| `gi` | Function | Fetches `.gitignore` templates from `gitignore.io`. |
| `bkr` | Function | Runs a command in the background with `nohup`; stdout and stderr go to a generated UUID filename. |
| `count` | Function | Prints the number of arguments passed to the function. |

## Install

From the repository root:

```sh
make zsh_run
```

Or from this directory:

```sh
make
```

The default install links:

- `zshenv` to `~/.zshenv`
- `zshrc` to `~/.zshrc`
- `alias.zsh` to `~/.alias.zsh`

If a destination file already exists and is not a symlink, the Makefile backs it
up before linking. This is useful when switching from Bash to ZSH for the first
time, because ZSH setup tools may create a starter `~/.zshrc`.

Example backup name:

```text
~/.zshrc.bak.20260527153000
```

## Optional zlogout

`zlogout` is intentionally not installed by default. Install it only if you want
the logout hook:

```sh
make install-zlogout
```

You can also install it together with the default files:

```sh
make WITH_ZLOGOUT=1
```

When installed, `zlogout` prints one randomly selected quote to stderr when an
interactive ZSH login shell exits.
