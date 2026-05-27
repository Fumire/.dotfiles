X11_LINKS := \
	Xdefaults:.Xdefaults \
	Xdefaults:.Xresources

LINKS ?= $(X11_LINKS)

all: install
.PHONY: all install macos defaults reload link

install: link

macos: install defaults reload

defaults:
	@if [ "$$(uname -s)" != "Darwin" ]; then \
		echo "XQuartz defaults are macOS-only; skipping."; \
		exit 0; \
	fi; \
	domain="org.xquartz.X11"; \
	defaults write "$$domain" sync_pasteboard -bool true; \
	defaults write "$$domain" sync_pasteboard_to_clipboard -bool true; \
	defaults write "$$domain" sync_pasteboard_to_primary -bool true; \
	defaults write "$$domain" sync_clipboard_to_pasteboard -bool true; \
	defaults write "$$domain" sync_primary_on_select -bool false; \
	defaults write "$$domain" sync_keymap -bool true; \
	echo "Configured XQuartz pasteboard sync. Restart XQuartz to apply server preferences."

reload:
	@if command -v xrdb >/dev/null 2>&1 && [ -n "$${DISPLAY:-}" ]; then \
		if xrdb -merge "$(HOME)/.Xresources"; then \
			echo "Merged X resources into the active X11 session."; \
		else \
			echo "Could not reload X resources through DISPLAY=$$DISPLAY. Restart XQuartz instead."; \
		fi; \
	else \
		echo "X resources installed. Start XQuartz or run 'xrdb -merge ~/.Xresources' inside an X11 session."; \
	fi

link:
	@set -eu; \
	for item in $(LINKS); do \
		src="$${item%%:*}"; \
		dest="$(HOME)/$${item#*:}"; \
		if [ -e "$$dest" ] && [ ! -L "$$dest" ]; then \
			backup="$$dest.bak.$$(date +%Y%m%d%H%M%S)"; \
			echo "Backing up $$dest to $$backup"; \
			mv "$$dest" "$$backup"; \
		fi; \
		ln -sfnv "$(CURDIR)/$$src" "$$dest"; \
	done
