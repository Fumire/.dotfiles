# X11

XQuartz compatibility settings for macOS.

## Problem

Recent macOS and XQuartz setups can make X11 clipboard behavior unreliable,
especially in `xterm` over an X11 session. Typical symptoms are:

- `Cmd+V` in `xterm` inserts nothing or unexpected characters.
- Text copied in macOS does not paste into X11 applications.
- Text selected or copied in X11 does not reach the macOS pasteboard.

The main mismatch is that macOS uses NSPasteboard, XQuartz syncs that with the
X11 `CLIPBOARD` selection, and older X11 applications such as `xterm` often use
`PRIMARY`.

## Install

From the repository root:

```sh
make x11_run
```

Or from this directory:

```sh
make macos
```

This links `Xdefaults` to both `~/.Xdefaults` and `~/.Xresources`, enables
XQuartz pasteboard synchronization, and reloads X resources when an X11 session
is already available.

Restart XQuartz after changing XQuartz preferences. For only the resource file,
you can reload it inside an active X11 session:

```sh
xrdb -merge ~/.Xresources
```

## SSH X11 Forwarding

macOS updates can overwrite the XQuartz SSH integration. If `ssh -X` or `ssh -Y`
starts failing with `xauth` warnings, make sure your SSH config contains:

```sshconfig
Host *
    XAuthLocation /opt/X11/bin/xauth
    ForwardX11Timeout 0
```

XQuartz should also have authentication enabled in Preferences > Security.
