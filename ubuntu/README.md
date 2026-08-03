# Ubuntu

Ubuntu-specific setup files for this dotfiles repository.

## Files

| File | Purpose |
| --- | --- |
| `Makefile` | Installs `screenrc` and writes Ubuntu-friendly R build settings (`$HOME/.R/Makevars`). |
| `screenrc` | GNU Screen configuration aligned with this repository's tmux-style key and status preferences. |
| `setup_r_makeflags.sh` | Writes `MAKEFLAGS = -j 10` to `$HOME/.R/Makevars`. |

## Requirements

* Ubuntu Linux (or compatible Linux shell environment)
* `make`

## Installation

From this directory:

```sh
make
```

From the repository root:

```sh
make -C ubuntu
```

This command:

* Links `ubuntu/screenrc` to `~/.screenrc`.
* Creates `~/.R` and writes `MAKEFLAGS = -j 10` to `~/.R/Makevars`.

`make` backs up any existing non-symlink destination file for `~/.screenrc` before creating the new symlink:

```text
~/.screenrc.bak.YYYYMMDDHHMMSS
```

The R `Makevars` command is intentionally simple and always writes the current flag value used in the script.

## Notes

If you want a different `MAKEFLAGS` value, edit `setup_r_makevars.sh` (or adjust the script and rerun `make`).



## Last Updated

- 2026-07-30
