all: $(HOME)/.config/nvim/stylua.toml $(HOME)/.config/nvim/lua/config/autocmds.lua $(HOME)/.config/nvim/lua/config/keymaps.lua $(HOME)/.config/nvim/lua/config/lazy.lua $(HOME)/.config/nvim/lua/config/options.lua $(HOME)/.config/nvim/lua/plugins/plugin.lua
.PHONY: all

$(HOME)/.config/nvim/stylua.toml: stylua.toml
	ln -sfv $(abspath $^) $@

$(HOME)/.config/nvim/lua/config/autocmds.lua: autocmds.lua
	ln -sfv $(abspath $^) $@

$(HOME)/.config/nvim/lua/config/keymaps.lua: keymaps.lua
	ln -sfv $(abspath $^) $@

$(HOME)/.config/nvim/lua/config/lazy.lua: lazy.lua
	ln -sfv $(abspath $^) $@

$(HOME)/.config/nvim/lua/config/options.lua: options.lua
	ln -sfv $(abspath $^) $@

$(HOME)/.config/nvim/lua/plugins/plugin.lua: plugin.lua
	ln -sfv $(abspath $^) $@
