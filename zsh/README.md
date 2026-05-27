# ZSH

ZSH configuration files for this dotfiles repository.

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
