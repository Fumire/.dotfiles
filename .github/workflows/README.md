# GitHub Workflows

GitHub Actions workflows for validating this dotfiles repository.

## Files

| File | Purpose |
| --- | --- |
| `ubuntu.yml` | Runs install smoke checks on `ubuntu-latest`. |
| `mac.yml` | Validates the macOS Homebrew profile and shell/editor install targets on `macos-15`. |
| `codeql.yml` | Runs CodeQL analysis for GitHub Actions workflow security. |

## Triggers

| Workflow | Triggers |
| --- | --- |
| `ubuntu.yml` | Pushes and pull requests targeting `master`. |
| `mac.yml` | Pushes and pull requests targeting `master`. |
| `codeql.yml` | Pushes and pull requests targeting `master`, a weekly scheduled run, and manual `workflow_dispatch`. |

## Ubuntu CI

`ubuntu.yml` checks the basic Linux install path:

1. Checks out the repository.
2. Installs `zsh` with `apt-get`.
3. Changes the current user's shell to `zsh`.
4. Runs `make zsh_run`.
5. Runs `make oh-my-zsh_run`.
6. Runs `make vim_run`.

This workflow verifies that the core ZSH, oh-my-zsh, and Vim symlink/install targets work on Ubuntu.

## macOS CI

`mac.yml` validates the macOS setup without installing the full bundle:

1. Checks out the repository without persisting credentials.
2. Syntax-checks `mac/Brewfile.Mac` with Ruby.
3. Uses `brew bundle list` to validate Brewfile entries.
4. Checks Homebrew metadata for listed formulae and casks.
5. Writes package counts to the GitHub Actions step summary.
6. Runs `zsh -n` against ZSH config files.
7. Runs `make zsh_run`.
8. Runs `make -C oh-my-zsh -n` as a dry run.
9. Runs `make vim_run`.

The workflow sets Homebrew environment variables to avoid upgrades, auto-update, and install cleanup during validation.

## CodeQL

`codeql.yml` analyzes GitHub Actions workflows:

1. Checks out the repository without persisting credentials.
2. Initializes CodeQL with `languages: actions`.
3. Runs CodeQL analysis with the `/language:actions` category.

The job grants only the permissions needed for Actions analysis and security-event upload.

## Notes

These workflows intentionally focus on smoke checks and static validation. They do not fully install every optional dotfiles component.
