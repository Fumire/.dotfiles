all: /usr/local/bin/brew free
.PHONY: all start brew bundle free $(HOME)/.mackup.cfg $(HOME)/.languagetool.cfg

start: starting.sh
	/usr/bin/env bash $(abspath $^)

brew:
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

bundle: Brewfile
	brew bundle --file=$(abspath $<) --verbose
	brew bundle check --file=$(abspath $<) --verbose

free: Brewfile.free
	brew bundle --file=$(abspath $<) --verbose
	brew bundle check --file=$(abspath $<) --verbose

$(HOME)/.mackup.cfg: mackup.cfg
	@set -eu; \
	mkdir -p "$(@D)"; \
	if [ -e "$@" ] && [ ! -L "$@" ]; then \
		backup="$@.bak.$$(date +%Y%m%d%H%M%S)"; \
		echo "Backing up $@ to $$backup"; \
		mv "$@" "$$backup"; \
	fi; \
	ln -sfnv "$(abspath $<)" "$@"

$(HOME)/.languagetool.cfg: languageserver.properties
	@set -eu; \
	mkdir -p "$(@D)"; \
	if [ -e "$@" ] && [ ! -L "$@" ]; then \
		backup="$@.bak.$$(date +%Y%m%d%H%M%S)"; \
		echo "Backing up $@ to $$backup"; \
		mv "$@" "$$backup"; \
	fi; \
	ln -sfnv "$(abspath $<)" "$@"
