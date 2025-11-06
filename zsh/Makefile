all: $(HOME)/.zshenv $(HOME)/.zshrc $(HOME)/.alias.zsh
.PHONY: all

$(HOME)/.zshenv: | zshenv
	ln -svf $(abspath $|) $@

$(HOME)/.zshrc: | zshrc
	ln -svf $(abspath $|) $@

$(HOME)/.zlogout: | zlogout
	ln -svf $(abspath $|) $@

$(HOME)/.alias.zsh: | alias.zsh
	ln -svf $(abspath $|) $@
