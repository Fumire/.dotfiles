ZSH_LINKS := \
	zshenv:.zshenv \
	zshrc:.zshrc \
	alias.zsh:.alias.zsh

ZSH_LOGOUT_LINK := zlogout:.zlogout

ifeq ($(WITH_ZLOGOUT),1)
ZSH_LINKS += $(ZSH_LOGOUT_LINK)
endif

LINKS ?= $(ZSH_LINKS)

all: install
.PHONY: all install install-zlogout zlogout link

install: link

install-zlogout: LINKS = $(ZSH_LOGOUT_LINK)
install-zlogout: link

zlogout: install-zlogout

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
