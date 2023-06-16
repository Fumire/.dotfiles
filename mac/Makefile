all: /usr/local/bin/brew free
.PHONY: all

start: starting.sh
	/usr/bin/env bash $(abspath $^)
.PHONY: start

brew:
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
.PHONY: brew

bundle: Brewfile
	brew bundle --file=$(abspath $<) --verbose
	brew bundle check --file=$(abspath $<) --verbose
.PHONY: bundle

free: Brewfile.free
	brew bundle --file=$(abspath $<) --verbose
	brew bundle check --file=$(abspath $<) --verbose
.PHONY: free

$(HOME)/.mackup.cfg: mackup.cfg
	ln -sf $^ $@

$(HOME)/.languagetool.cfg: languageserver.properties
	ln -sf $^ $@
