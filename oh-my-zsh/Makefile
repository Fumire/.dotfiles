all: $(HOME)/.oh-my-zsh $(HOME)/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting $(HOME)/.oh-my-zsh/themes/local.zsh-theme $(HOME)/.oh-my-zsh/themes/remote.zsh-theme
.PHONY += all

$(HOME)/.oh-my-zsh:
	sh -c "${curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh}"

$(HOME)/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting:
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $@

$(HOME)/.oh-my-zsh/themes/local.zsh-theme: $(HOME)/.dotfiles/oh-my-zsh/themes/local.zsh-theme $(HOME)/.oh-my-zsh
	ln -sf $< $@

$(HOME)/.oh-my-zsh/themes/remote.zsh-theme: $(HOME)/.dotfiles/oh-my-zsh/themes/remote.zsh-theme $(HOME)/.oh-my-zsh
	ln -sf $< $@
