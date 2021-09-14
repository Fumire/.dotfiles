all: $(HOME)/.vimrc $(HOME)/.style.yapf $(HOME)/Library/Preferences/TabNine/TabNine.toml
.PHONY: all

$(HOME)/.vimrc: | vimrc
	ln -sf $(abspath $|) $@

$(HOME)/.style.yapf: | style.yapf
	ln -sf $(abspath $|) $@

$(HOME)/Library/Preferences/TabNine/TabNine.toml: | TabNine.toml
	mkdir -p $(@D)
	ln -sf $(abspath $|) $@
