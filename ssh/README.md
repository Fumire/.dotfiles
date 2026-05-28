# SSH Configuration

Personal SSH configuration and helper targets for this dotfiles repository.

## Files

| File | Purpose |
| --- | --- |
| `config` | Shared SSH client defaults for all hosts. |
| `Makefile` | Helper targets for linking SSH config, appending a public key, and decrypting private keys. |
| `.gitignore` | Ignores local `*.pub` files so public keys can be used by helper targets without being tracked. |

## SSH Defaults

The `config` file applies these settings to all SSH hosts:

* Enables host IP checking and hashed known hosts
* Enables compression
* Adds AES cipher options
* Enables trusted X11 forwarding
* Sends locale environment variables matching `LC_*`
* Sends keepalive packets every 60 seconds

Review these defaults before using the file on shared or security-sensitive systems. In particular, X11 forwarding and legacy cipher compatibility should be enabled only when needed.

## Installation

The default `make -C ssh` target does nothing. Install the SSH config by requesting the explicit target:

```sh
make -C ssh "$HOME/.ssh/config"
```

This creates:

* `ssh/config` -> `~/.ssh/config`

The target also runs:

```sh
chmod 600 ~/.ssh/config
```

## Authorized Keys

To append `ssh/id_rsa.pub` to `~/.ssh/authorized_keys`, place the public key at `ssh/id_rsa.pub`, then run:

```sh
make -C ssh add_key
```

This creates `~/.ssh/authorized_keys` if it does not exist and appends the public key to it.

## Private Key Decryption

The Makefile can decrypt private keys stored as GPG-encrypted files under `~/Documents/PrivateKeys`.

For example:

```sh
make -C ssh decrypt_key
```

This expects:

* `~/Documents/PrivateKeys/id_rsa.asc`

And creates:

* `~/.ssh/id_rsa`

The generated private key is set to mode `400`.

Pattern targets are also available. For example, this command expects `~/Documents/PrivateKeys/id_ed25519.asc` and creates `~/.ssh/id_ed25519`:

```sh
make -C ssh "$HOME/.ssh/id_ed25519"
```

## Notes

Do not commit private keys. Public key files matching `*.pub` are also ignored in this folder.

If `~/.ssh/config` already exists and is not a symlink, the Makefile backs it up before linking. Review SSH backups carefully because they may contain host-specific settings.
