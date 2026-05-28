all: zsh_run oh-my-zsh_run vim_run
.PHONY: all

mac_run:
	$(MAKE) -C mac free
.PHONY: mac_run

vim_run:
	$(MAKE) -C vim install-vimrc
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
	$(MAKE) -C gnupg legacy
.PHONY: gnupg_run
