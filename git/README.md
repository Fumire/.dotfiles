# Git Configuration

Personal Git configuration managed by this dotfiles repository.

## Files

* `gitconfig`: Global Git settings, including user identity, GPG signing, default branch name, pull/rebase behavior, merge/diff tools, Git LFS filters, and credential helper settings.
* `gitignore_global`: Global ignore rules for editor backup files, Vim swap files, macOS metadata files, and common local cache directories.

## `gitconfig`

The `gitconfig` file is intended to be linked as `~/.gitconfig`. It configures these areas:

| Section | Setting |
| --- | --- |
| `[user]` | Sets the commit author name, email address, and GPG signing key. |
| `[core]` | Uses `vi` as the editor, reads global ignore rules from `~/.gitignore_global`, enables high compression, and uses `less -F -X` as the pager. |
| `[init]` | Creates new repositories with `main` as the default branch. |
| `[blame]` | Highlights repeated lines in `git blame`. |
| `[push]` | Uses `simple` push behavior and signs pushes when the remote asks for it. |
| `[pull]` | Rebases local commits on pull instead of creating merge commits. |
| `[merge]` | Disables fast-forward-only merge behavior, enables rename detection, and uses `vimdiff` as the GUI merge tool. |
| `[fetch]` | Prunes deleted remote refs and validates fetched objects. |
| `[commit]` | Signs commits with GPG by default. |
| `[filter "lfs"]` | Enables Git LFS clean, smudge, and process filters. |
| `[gpg]` | Uses the `gpg` command for signing. |
| `[color]` | Enables automatic color output for status, branch, interactive, and diff commands. |
| `[diff]` | Uses `vimdiff` as the diff tool and the `minimal` diff algorithm. |
| `[pack]` | Uses high compression for packed Git objects. |
| `[sendmail]` | Sets the default sender address for `git send-email`. |
| `[ssh]` | Uses OpenSSH as the SSH variant. |
| `[credential]` | Uses the macOS `osxkeychain` credential helper. |
| `[pager]` | Enables paging for `git status`. |
| `[oh-my-zsh]` | Hides dirty-status checks in oh-my-zsh Git prompts. |
| `[transfer]` and `[receive]` | Validate transferred and received Git objects. |
| `[log]` | Shows commit dates in ISO format. |

## Installation

Run this from the repository root:

```sh
make git_run
```

This creates the following symbolic links:

* `git/gitconfig` -> `~/.gitconfig`
* `git/gitignore_global` -> `~/.gitignore_global`

## Notes

This configuration enables signed commits by default and uses `gpg` as the signing program. Make sure the configured signing key is available on the machine before creating commits.

The credential helper is set to `osxkeychain`, which is intended for macOS. On other operating systems, update `credential.helper` after installation if needed.
