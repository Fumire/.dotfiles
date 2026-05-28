GNUPG_LINKS := \
	gpg.conf:.gnupg/gpg.conf \
	gpg-agent.conf:.gnupg/gpg-agent.conf

GNUPG_LEGACY_LINKS := \
	gpg.conf:.gpg.conf \
	gpg-agent.conf:.gpg-agent.conf

LINKS ?= $(GNUPG_LINKS)

all: install
.PHONY: all install legacy reload link

install: link

legacy: LINKS = $(GNUPG_LEGACY_LINKS)
legacy: link reload

reload:
	gpgconf --kill gpg-agent

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
