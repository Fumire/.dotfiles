all: vim zsh tmux git
.PHONY += all

update:
	git fetch --all
	git reset --hard origin/master
	. $(HOME)/.zshrc
.PHONY += update

vim: $(HOME)/.vimrc $(HOME)/.ycm_extra_conf.py $(HOME)/.style.yapf
.PHONY += vim

$(HOME)/.vimrc: $(HOME)/.dotfiles/vim/vimrc
	ln -sf $< $@

$(HOME)/.ycm_extra_conf.py: $(HOME)/.dotfiles/vim/ycm_extra_conf.py
	ln -sf $< $@

$(HOME)/.style.yapf: $(HOME)/.dotfiles/vim/style.yapf

zsh: $(HOME)/.zshrc $(HOME)/.alias.zsh $(HOME)/.oh-my-zsh/themes/local.zsh-theme
.PHONY += zsh

$(HOME)/.oh-my-zsh:
	sh -c "${curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh}"

$(HOME)/.zshrc: $(HOME)/.dotfiles/zsh/zshrc
	ln -sf $< $@

$(HOME)/.alias.zsh: $(HOME)/.dotfiles/zsh/alias.zsh
	ln -sf $< $@

$(HOME)/.oh-my-zsh/themes/local.zsh-theme: $(HOME)/.dotfiles/oh-my-zsh/themes/local.zsh-theme $(HOME)/.oh-my-zsh
	ln -sf $< $@

$(HOME)/.oh-my-zsh/themes/remote.zsh-theme: $(HOME)/.dotfiles/oh-my-zsh/themes/remote.zsh-theme $(HOME)/.oh-my-zsh
	ln -sf $< $@

tmux: $(HOME)/.tmux.conf $(HOME)/.tmux.conf.local
.PHONY += tmux

$(HOME)/.tmux.conf: $(HOME)/.dotfiles/tmux/tmux.conf
	ln -sf $< $@

$(HOME)/.tmux.conf.local: $(HOME)/.dotfiles/tmux/tmux.conf.local
	ln -sf $< $@

git: $(HOME)/.gitignore_global $(HOME)/.gitconfig
	git config --global core.excludesfile $<
.PHONY += git

$(HOME)/.gitconfig: $(HOME)/.dotfiles/git/gitconfig
	ln -sf $< $@

$(HOME)/.gitignore_global: $(HOME)/.dotfiles/git/gitignore_global
	ln -sf $< $@
