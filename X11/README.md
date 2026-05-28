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

Another known XQuartz issue on Apple Silicon is that some X11 application
windows render with a black background or black overlay. Screenshots can show
the affected area as transparent even though it looks black on screen. This is
reported with applications such as Android Studio, PyCharm, IntelliJ, MATLAB,
and Ghidra.

## References

Clipboard behavior and XTerm resources:

- [XTerm copy and paste](https://xterm.dev/copy-and-paste/) explains that
  unconfigured XTerm copies to `PRIMARY` and recommends
  `XTerm.vt100.selectToClipboard: true` when the expected target is
  `CLIPBOARD`.
- [xterm(1) SELECT/PASTE documentation](https://manpages.debian.org/buster/xterm/xterm.1.en.html)
  documents `PRIMARY`, `CLIPBOARD`, `CUT_BUFFER`, `keepSelection`, and
  `selectToClipboard`.
- [Stack Overflow: `Xterm*selectToClipboard` does not work in Xresources](https://stackoverflow.com/questions/29551162/xtermselecttoclipboard-doesnt-work-when-put-in-xresources)
  notes that X resource names are case-sensitive and discusses checking merged
  resources with tools such as `xrdb` and `appres`.
- [StarNet: Copying and Pasting in Xterm](https://www.starnet.com/help/copying-and-pasting-in-xterm/)
  gives the same practical workaround: set `XTerm*selectToClipboard: true`
  when an environment expects `CLIPBOARD`.

XQuartz and SSH X11 forwarding:

- [XQuartz FAQ: ssh X forwarding debugging](https://www.xquartz.org/FAQs.html)
  documents the `xauth` warning, `XAuthLocation /opt/X11/bin/xauth`,
  authenticated connections, and `ForwardX11Timeout 0`.
- [Stack Overflow: `ssh -X` warning about xauth key data](https://stackoverflow.com/questions/27384725/ssh-x-warning-untrusted-x11-forwarding-setup-failed-xauth-key-data-not-gener)
  covers the common macOS/XQuartz case where SSH looks for `xauth` in the wrong
  path.

Black background rendering on Apple Silicon:

- [XQuartz issue #31: Apple Silicon black background](https://github.com/XQuartz/XQuartz/issues/31)
  tracks the black or transparent-background rendering problem on Apple Silicon.
- [Ask Different: black background workaround](https://apple.stackexchange.com/questions/475300/how-can-i-fix-a-black-background-when-using-xquartz-on-an-apple-silicon-mac)
  documents disabling the XQuartz render extension with
  `defaults write org.xquartz.X11 enable_render_extension 0`.
- [Ask Different: Java VM option workaround](https://apple.stackexchange.com/questions/428589/xquartz-has-a-black-background-with-all-apps)
  notes `-Dsun.java2d.xrender=false` as a Java application workaround.

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

## Apple Silicon Black Background

On Apple Silicon Macs, some X11 applications may show a black background, black
overlay, or unreadable dark rendering even though screenshots show the window
background as transparent. The broad workaround is to disable the XQuartz render
extension:

```sh
defaults write org.xquartz.X11 enable_render_extension 0
```

Then quit and restart XQuartz.

If the affected application is Java-based and the XQuartz setting is not enough,
try disabling Java2D XRender for that application:

```sh
export JAVA_TOOL_OPTIONS="-Dsun.java2d.xrender=false"
```

For JetBrains or other Java GUI applications, set the option in the application
launcher, startup script, or shell environment used to start the remote
application.

To undo the XQuartz render-extension override:

```sh
defaults delete org.xquartz.X11 enable_render_extension
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
