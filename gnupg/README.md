# GnuPG Configuration

Personal GnuPG configuration for this dotfiles repository.

## Files

| File | Purpose |
| --- | --- |
| `gpg-agent.conf` | GPG agent cache and pinentry settings. |
| `gpg.conf` | Main GPG behavior settings. |
| `Makefile` | Installs the config files under `~/.gnupg`. |

## `gpg.conf`

| Setting | Meaning |
| --- | --- |
| `auto-key-retrieve` | Automatically retrieves missing public keys when verifying signatures. This is convenient, but it can contact configured keyservers during verification. |
| `no-emit-version` | Omits the GnuPG version from generated output where applicable. |
| `no-tty` | Prevents GPG from using the terminal directly for output, which is useful for scripted or GUI-driven workflows. |

## `gpg-agent.conf`

| Setting | Meaning |
| --- | --- |
| `default-cache-ttl 1` | Caches a passphrase for only 1 second by default. |
| `max-cache-ttl 1` | Caps passphrase caching at 1 second. |
| `pinentry-program /opt/homebrew/bin/pinentry-mac` | Uses Homebrew's macOS Pinentry program for passphrase prompts. |

The cache settings prioritize security over convenience. Expect to be prompted for the passphrase frequently.

The configured `pinentry-program` path is macOS/Homebrew-specific. On Linux or Intel Homebrew installations, update this path before use.

## Installation

Recommended GnuPG directory layout:

```sh
make -C gnupg
```

This creates:

* `gnupg/gpg.conf` -> `~/.gnupg/gpg.conf`
* `gnupg/gpg-agent.conf` -> `~/.gnupg/gpg-agent.conf`

The top-level Makefile also provides:

```sh
make gnupg_run
```

This creates:

* `gnupg/gpg.conf` -> `~/.gpg.conf`
* `gnupg/gpg-agent.conf` -> `~/.gpg-agent.conf`

and restarts the agent with:

```sh
gpgconf --kill gpg-agent
```

## Reloading

After changing `gpg-agent.conf`, restart the agent:

```sh
gpgconf --kill gpg-agent
```

GnuPG will start a new agent the next time it needs one.

## Notes

If a destination config file already exists and is not a symlink, the Makefile backs it up before linking.

Do not commit private keys, revocation certificates, trust databases, or keyring files to this repository.
