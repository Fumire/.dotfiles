UBUNTU_LINKS := \
	screenrc:.screenrc

LINKS ?= $(UBUNTU_LINKS)
R_MAKEVARS_SCRIPT := setup_r_makeflags.sh

all: install
.PHONY: all install link setup-r-makevars

install: link setup-r-makevars

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

setup-r-makevars:
	@/usr/bin/env bash "$(CURDIR)/$(R_MAKEVARS_SCRIPT)"
