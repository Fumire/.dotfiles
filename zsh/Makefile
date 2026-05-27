ZSH_LINKS := \
	zshenv:.zshenv \
	zshrc:.zshrc \
	alias.zsh:.alias.zsh \
	zlogout:.zlogout

all: install
.PHONY: all install

install:
	@set -eu; \
	for item in $(ZSH_LINKS); do \
		src="$${item%%:*}"; \
		dest="$(HOME)/$${item#*:}"; \
		if [ -e "$$dest" ] && [ ! -L "$$dest" ]; then \
			backup="$$dest.bak.$$(date +%Y%m%d%H%M%S)"; \
			echo "Backing up $$dest to $$backup"; \
			mv "$$dest" "$$backup"; \
		fi; \
		ln -sfnv "$(CURDIR)/$$src" "$$dest"; \
	done
