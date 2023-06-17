all: zsh_run oh-my-zsh_run vim_run
.PHONY: all

mac_run:
	$(MAKE) -C mac free
.PHONY: mac_run

update:
	git fetch --all
	git reset --hard origin/master
.PHONY: update

vim_run:
	$(MAKE) -C vim
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

gnupg_run:
	$(MAKE) -C gnupg
.PHONY: gnupg_run
