all: $(HOME)/.gitignore_global $(HOME)/.gitconfig
.PHONY += git

$(HOME)/.gitconfig: gitconfig
	ln -sf $(abspath $<) $@

$(HOME)/.gitignore_global: gitignore_global
	ln -sf $(abspath $<) $@
	git config --global core.excludesfile $@
