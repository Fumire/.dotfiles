all: $(HOME)/.zshrc $(HOME)/.alias.zsh
.PHONY += all

$(HOME)/.zshrc: zshrc
	ln -sf $< $@

$(HOME)/.alias.zsh: alias.zsh
	ln -sf $< $@
