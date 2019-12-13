all: $(HOME)/.gitignore_global $(HOME)/.gitconfig
.PHONY += git

$(HOME)/.gitconfig: gitconfig
	ln -sf $< $@

$(HOME)/.gitignore_global: gitignore_global
	ln -sf $< $@
	git config --global core.excludesfile $@
