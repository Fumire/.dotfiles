all: $(HOME)/.zshenv $(HOME)/.zshrc $(HOME)/.zlogout $(HOME)/.alias.zsh
.PHONY: all

$(HOME)/.zshenv: zshenv
	which $$SHELL | grep "zsh" > /dev/null || chsh -s $$(which zsh)
	ln -sf $(abspath $<) $@

$(HOME)/.zshrc: zshrc
	which $$SHELL | grep "zsh" > /dev/null || chsh -s $$(which zsh)
	ln -sf $(abspath $<) $@

$(HOME)/.zlogout: zlogout
	which $$SHELL | grep "zsh" > /dev/null || chsh -s $$(which zsh)
	ln -sf $(abspath $<) $@

$(HOME)/.alias.zsh: alias.zsh
	ln -sf $(abspath $<) $@
