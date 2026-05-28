all: zsh_run oh-my-zsh_run vim_run
.PHONY: all

mac_run:
	$(MAKE) -C mac free
.PHONY: mac_run

vim_run:
	$(MAKE) -C vim $(HOME)/.vimrc
.PHONY: vim_run

zsh_run:
	$(MAKE) -C zsh
.PHONY: zsh_run

oh-my-zsh_run:
	$(MAKE) -C oh-my-zsh
.PHONY: oh-my-zsh_run

tmux_run:
	$(MAKE) -C tmux
.PHONY: tmux_run

git_run:
	$(MAKE) -C git
.PHONY: git_run

x11_run:
	$(MAKE) -C X11 macos
.PHONY: x11_run

gnupg_run:
	ln -sfv $(realpath gnupg/gpg.conf) ~/.gpg.conf
	ln -sfv $(realpath gnupg/gpg-agent.conf) ~/.gpg-agent.conf
	gpgconf --kill gpg-agent
.PHONY: gnupg_run
