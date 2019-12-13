all: $(HOME)/.vimrc $(HOME)/.ycm_extra_conf.py $(HOME)/.style.yapf $(HOME)/Library/Preferences/TabNine/TabNine.toml
.PHONY += all

$(HOME)/.vimrc: vimrc
	ln -sf $< $@

$(HOME)/.ycm_extra_conf.py: ycm_extra_conf.py
	ln -sf $< $@

$(HOME)/.style.yapf: style.yapf
	ln -sf $< $@

$(HOME)/Library/Preferences/TabNine/TabNine.toml: TabNine.toml
	ln -sf $< $@
