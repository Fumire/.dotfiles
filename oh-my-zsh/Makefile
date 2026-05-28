all: $(HOME)/.oh-my-zsh $(HOME)/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting $(HOME)/.oh-my-zsh/themes/local.zsh-theme $(HOME)/.oh-my-zsh/themes/remote.zsh-theme
.PHONY: all $(HOME)/.oh-my-zsh/themes/local.zsh-theme $(HOME)/.oh-my-zsh/themes/remote.zsh-theme

$(HOME)/.oh-my-zsh:
	curl -fsSL "https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh" | sh

$(HOME)/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting:
	git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" $@

$(HOME)/.oh-my-zsh/themes/local.zsh-theme: themes/local.zsh-theme $(HOME)/.oh-my-zsh
	@set -eu; \
	mkdir -p "$(dir $@)"; \
	if [ -e "$@" ] && [ ! -L "$@" ]; then \
		backup="$@.bak.$$(date +%Y%m%d%H%M%S)"; \
		echo "Backing up $@ to $$backup"; \
		mv "$@" "$$backup"; \
	fi; \
	ln -sfnv "$(abspath $<)" "$@"

$(HOME)/.oh-my-zsh/themes/remote.zsh-theme: themes/remote.zsh-theme $(HOME)/.oh-my-zsh
	@set -eu; \
	mkdir -p "$(dir $@)"; \
	if [ -e "$@" ] && [ ! -L "$@" ]; then \
		backup="$@.bak.$$(date +%Y%m%d%H%M%S)"; \
		echo "Backing up $@ to $$backup"; \
		mv "$@" "$$backup"; \
	fi; \
	ln -sfnv "$(abspath $<)" "$@"
