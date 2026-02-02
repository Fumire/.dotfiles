all: zsh_run oh-my-zsh_run vim_run
.PHONY: all

mac_run:
	$(MAKE) -C mac free
.PHONY: mac_run

vim_run:
	ln -sfv $(realpath vim/vimrc) ~/.vimrc
.PHONY: vim_run

zsh_run:
	ln -sfv $(realpath zsh/zshenv) ~/.zshenv
	ln -sfv $(realpath zsh/zshrc) ~/.zshrc
	ln -sfv $(realpath zsh/alias.zsh) ~/.alias.zsh
.PHONY: zsh_run

oh-my-zsh_run:
	$(MAKE) -C oh-my-zsh
.PHONY: oh-my-zsh_run

tmux_run:
	ln -sfv $(realpath tmux/tmux.conf) ~/.tmux.conf
	ln -sfv $(realpath tmux/tmux.conf.local) ~/.tmux.conf.local
.PHONY: tmux_run

git_run:
	ln -sfv $(realpath git/gitconfig) ~/.gitconfig
	ln -sfv $(realpath git/gitignore_global) ~/.gitignore_global
.PHONY: git_run

gnupg_run:
	ln -sfv $(realpath gnupg/gpg.conf) ~/.gpg.conf
	ln -sfv $(realpath gnupg/gpg-agent.conf) ~/.gpg-agent.conf
	gpgconf --kill gpg-agent
.PHONY: gnupg_run
