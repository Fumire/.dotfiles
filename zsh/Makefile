all: $(HOME)/.zshrc $(HOME)/.alias.zsh
.PHONY: all

$(HOME)/.zshrc:
	which $$SHELL | grep "zsh" || chsh -s $$(which zsh)
	ln -sf $(abspath $<) $@

$(HOME)/.alias.zsh: alias.zsh
	ln -sf $(abspath $<) $@
