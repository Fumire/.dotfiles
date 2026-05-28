TMUX_LINKS := \
	tmux.conf:.tmux.conf \
	tmux.conf.local:.tmux.conf.local

LINKS ?= $(TMUX_LINKS)

all: install
.PHONY: all install link

install: link

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
