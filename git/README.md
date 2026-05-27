# Git Configuration

Personal Git configuration managed by this dotfiles repository.

## Files

* `gitconfig`: Global Git settings, including user identity, GPG signing, default branch name, pull/rebase behavior, merge/diff tools, Git LFS filters, and credential helper settings.
* `gitignore_global`: Global ignore rules for editor backup files, Vim swap files, macOS metadata files, and common local cache directories.

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
