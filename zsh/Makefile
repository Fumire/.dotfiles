all: $(HOME)/.zshenv $(HOME)/.zshrc $(HOME)/.alias.zsh
.PHONY: all

$(HOME)/.zshenv: | zshenv
	ln -sf $(abspath $|) $@

$(HOME)/.zshrc: | zshrc
	ln -sf $(abspath $|) $@

$(HOME)/.zlogout: | zlogout
	ln -sf $(abspath $|) $@

$(HOME)/.alias.zsh: | alias.zsh
	ln -sf $(abspath $|) $@
