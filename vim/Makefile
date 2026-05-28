VIM_LINKS := \
	style.yapf:.style.yapf \
	TabNine.toml:Library/Preferences/TabNine/TabNine.toml \
	tabnine_config.json:Library/Preferences/TabNine/tabnine_config.json

VIMRC_LINK := vimrc:.vimrc

LINKS ?= $(VIM_LINKS)

all: install
.PHONY: all install install-vimrc link

install: link

install-vimrc: LINKS = $(VIMRC_LINK)
install-vimrc: link

link:
	@set -eu; \
	for item in $(LINKS); do \
		src="$${item%%:*}"; \
		dest="$(HOME)/$${item#*:}"; \
		mkdir -p "$$(dirname "$$dest")"; \
		if [ -e "$$dest" ] && [ ! -L "$$dest" ]; then \
			backup="$$dest.bak.$$(date +%Y%m%d%H%M%S)"; \
			echo "Backing up $$dest to $$backup"; \
			mv "$$dest" "$$backup"; \
		fi; \
		ln -sfnv "$(CURDIR)/$$src" "$$dest"; \
	done
