all: $(HOME)/.vimrc $(HOME)/.ycm_extra_conf.py $(HOME)/.style.yapf $(HOME)/Library/Preferences/TabNine/TabNine.toml
.PHONY += all

$(HOME)/.vimrc: vimrc
	ln -sf $(abspath $<) $@

$(HOME)/.ycm_extra_conf.py: ycm_extra_conf.py
	ln -sf $(abspath $<) $@

$(HOME)/.style.yapf: style.yapf
	ln -sf $(abspath $<) $@

$(HOME)/Library/Preferences/TabNine/TabNine.toml: TabNine.toml
	ln -sf $(abspath $<) $@
