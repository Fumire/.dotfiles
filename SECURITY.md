# Security Policy

This repository contains personal dotfiles, shell scripts, editor settings,
SSH/Git/GnuPG configuration, Homebrew manifests, and GitHub Actions workflows.
Security reports should focus on issues that could expose secrets, weaken local
machine security, or cause unsafe behavior when these dotfiles are installed.

## Supported Versions

This repository does not publish versioned releases. Security fixes are applied
to the default branch only.

| Branch | Supported |
| ------ | --------- |
| `master` | Yes |
| Other branches or forks | No |

## Reporting a Vulnerability

Do not open a public GitHub issue for a suspected vulnerability.

Report security issues by email:

```text
230@fumire.moe
```

If GitHub private vulnerability reporting is enabled for this repository, you
may also use GitHub's private reporting flow.

Include as much of the following as possible:

- Affected file, command, workflow, or installation target.
- The operating system and shell where the issue occurs.
- Steps to reproduce the issue from a clean checkout.
- Expected behavior and actual behavior.
- Security impact, such as secret exposure, unsafe permissions, command
  injection, network exposure, or privilege escalation.
- Any relevant logs, redacted to remove secrets, tokens, hostnames, private
  keys, or personal data.

Reports are handled on a best-effort basis. I will try to acknowledge valid
reports within 7 days and provide an update when a fix or mitigation is
available.

## Scope

Security reports are in scope when they affect this repository's install or
runtime behavior, including:

- Installation targets that overwrite files unexpectedly or set unsafe
  permissions.
- Shell scripts that execute untrusted input, use unsafe temporary files, or
  expose sensitive local data.
- SSH, Git, GnuPG, tmux, ZSH, Vim, Neovim, X11, or macOS configuration that
  materially weakens local security.
- GitHub Actions workflows that expose secrets, grant excessive permissions, or
  run untrusted code unsafely.
- Accidental commits of credentials, private keys, tokens, machine-specific
  secrets, or personal data.

The following are usually out of scope:

- Personal preference changes, aliases, keybindings, editor behavior, or theme
  choices without a security impact.
- Vulnerabilities in upstream projects such as Homebrew, oh-my-zsh, XQuartz,
  Vim, Neovim, tmux, Git, OpenSSH, or GitHub Actions runners.
- Issues that require prior full control of the local user account and do not
  create additional exposure.

## Secret Handling

This repository should not contain private keys, access tokens, passwords,
machine-specific secrets, or decrypted credentials. If you find a committed
secret, report it privately and treat it as compromised.

Recommended remediation for exposed secrets:

1. Revoke or rotate the exposed credential.
2. Remove the secret from the current tree.
3. Consider rewriting history if the repository owner decides the operational
   cost is justified.
4. Audit recent access logs for abuse where available.

## Secure Installation Expectations

Before running install targets on a real machine, review the target and the
files it links or modifies. This repository intentionally changes files under
`$HOME`, and some targets may affect shell startup, SSH behavior, GnuPG agent
state, Homebrew packages, or XQuartz settings.

Prefer testing install behavior with a temporary home directory first:

```sh
tmp_home="$(mktemp -d)"
HOME="$tmp_home" make zsh_run
```

Do not run scripts from an untrusted checkout.
