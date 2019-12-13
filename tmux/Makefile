all: $(HOME)/.tmux.conf $(HOME)/.tmux.conf.local
.PHONY += all

$(HOME)/.tmux.conf: tmux.conf
	ln -sf $< $@

$(HOME)/.tmux.conf.local: tmux.conf.local
	ln -sf $< $@
