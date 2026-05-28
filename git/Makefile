GIT_LINKS := \
	gitconfig:.gitconfig \
	gitignore_global:.gitignore_global

LINKS ?= $(GIT_LINKS)

all: install
.PHONY: all install link

install: link

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
