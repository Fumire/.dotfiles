all: $(HOME)/.zshenv $(HOME)/.zshrc $(HOME)/.alias.zsh
.PHONY: all

$(HOME)/.zshenv: | zshenv
	ln -sf $(abspath $|) $@
	bash zsh.bash

$(HOME)/.zshrc: | zshrc
	ln -sf $(abspath $|) $@
	bash zsh.bash

$(HOME)/.zlogout: | zlogout
	ln -sf $(abspath $|) $@
	bash zsh.bash

$(HOME)/.alias.zsh: | alias.zsh
	ln -sf $(abspath $|) $@
	bash zsh.bash
