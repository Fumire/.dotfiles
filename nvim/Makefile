NVIM_LINKS := \
	stylua.toml:.config/nvim/stylua.toml \
	autocmds.lua:.config/nvim/lua/config/autocmds.lua \
	keymaps.lua:.config/nvim/lua/config/keymaps.lua \
	lazy.lua:.config/nvim/lua/config/lazy.lua \
	options.lua:.config/nvim/lua/config/options.lua \
	plugin.lua:.config/nvim/lua/plugins/plugin.lua

LINKS ?= $(NVIM_LINKS)

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
