all: $(HOME)/.zshenv $(HOME)/.zshrc $(HOME)/.alias.zsh
.PHONY: all

$(HOME)/.zshenv: | zshenv
	bash zsh.bash
	ln -sf $(abspath $|) $@

$(HOME)/.zshrc: | zshrc
	bash zsh.bash
	ln -sf $(abspath $|) $@

$(HOME)/.zlogout: | zlogout
	bash zsh.bash
	ln -sf $(abspath $|) $@

$(HOME)/.alias.zsh: | alias.zsh
	bash zsh.bash
	ln -sf $(abspath $|) $@
