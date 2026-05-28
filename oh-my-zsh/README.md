# oh-my-zsh Configuration

oh-my-zsh installer and custom prompt themes for this dotfiles repository.

## Files

| File | Purpose |
| --- | --- |
| `Makefile` | Installs oh-my-zsh, installs `zsh-syntax-highlighting`, and links custom themes into `~/.oh-my-zsh/themes`. |
| `themes/local.zsh-theme` | Local-machine prompt theme. |
| `themes/remote.zsh-theme` | SSH/remote prompt theme. |

## Requirements

* `zsh`
* `git`
* `curl`
* Network access for the oh-my-zsh installer and plugin clone
* A Powerline-compatible font for prompt separators and symbols

## Installation

From the repository root:

```sh
make oh-my-zsh_run
```

Or from this directory:

```sh
make
```

The Makefile performs these actions:

* Installs oh-my-zsh into `~/.oh-my-zsh` if it is missing.
* Clones `zsh-users/zsh-syntax-highlighting` into `~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting`.
* Links `themes/local.zsh-theme` to `~/.oh-my-zsh/themes/local.zsh-theme`.
* Links `themes/remote.zsh-theme` to `~/.oh-my-zsh/themes/remote.zsh-theme`.

If an existing theme file with the same name is not a symlink, the Makefile backs it up before linking.

## Theme Selection

The main zsh configuration in `../zsh/zshrc` chooses the theme based on the session:

```zsh
if [[ -n "$SSH_CONNECTION" ]]; then
    ZSH_THEME="remote"
else
    ZSH_THEME="local"
fi
```

Use `local` for normal local shells and `remote` for SSH sessions.

## Themes

Both themes are Bullet Train-style segmented prompts. They share the same prompt rendering functions and most segment settings.

Default local prompt order:

```zsh
time context status dir git cmd_exec_time
```

Default remote prompt order:

```zsh
time context status dir screen git cmd_exec_time
```

The remote theme adds the `screen` segment so GNU Screen sessions are visible in the prompt.

Common segments:

| Segment | Behavior |
| --- | --- |
| `time` | Shows the current time. |
| `context` | Shows `user@host` when relevant. The local theme treats `fumire` as the default user. |
| `status` | Shows failed command status, root shell indicator, and background job indicator. |
| `dir` | Shows the current directory, shortened to a medium-length path by default. |
| `git` | Shows Git branch and working-tree status using oh-my-zsh Git prompt helpers. |
| `screen` | Shows the GNU Screen session name when `$STY` is set; enabled by default in the remote theme. |
| `cmd_exec_time` | Shows elapsed time for commands that run longer than 5 seconds. |

Optional prompt functions are also present for virtualenv/pyenv, nvm/node, AWS profile, Ruby, Go, Rust, Kubernetes context, Elixir, Perl, Mercurial, and custom messages. Add them to `BULLETTRAIN_PROMPT_ORDER` before loading oh-my-zsh if you want them displayed.

## Customization

The themes use `BULLETTRAIN_*` variables for colors, prefixes, and prompt behavior. Set those variables before oh-my-zsh is loaded to override defaults.

Examples:

```zsh
BULLETTRAIN_PROMPT_SEPARATE_LINE=false
BULLETTRAIN_EXEC_TIME_ELAPSED=10
BULLETTRAIN_GIT_COLORIZE_DIRTY=true
BULLETTRAIN_PROMPT_ORDER=(time status dir git cmd_exec_time)
```

## Notes

The oh-my-zsh install target runs the upstream installer with:

```sh
curl -fsSL "https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh" | sh
```

Review the upstream installer behavior before running it on a machine with an existing zsh setup, because it may create or modify shell startup files.
