all: /usr/local/bin/brew no_mas
.PHONY: all

start: starting.sh
	/usr/bin/env bash $(abspath $^)
.PHONY: start

/usr/local/bin/brew:
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

bundle: Brewfile | /usr/local/bin/brew
	brew bundle --file=$(abspath $<) --verbose
	brew bundle check --file=$(abspath $<) --verbose
.PHONY: bundle

free: Brewfile.free | /usr/local/bin/brew
	brew bundle --file=$(abspath $<) --verbose
	brew bundle check --file=$(abspath $<) --verbose
.PHONY: free

no_mas: Brewfile.no_mas | /usr/local/bin/brew
	brew bundle --file=$(abspath $<) --verbose
	brew bundle check --file=$(abspath $<) --verbose
.PHONY: no_mas
