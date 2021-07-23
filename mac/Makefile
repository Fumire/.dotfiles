all: /usr/local/bin/brew
.PHONY: all

start: starting.sh
	sh $<
.PHONY: start

bundle: Brewfile | /usr/local/bin/brew
	brew bundle --file=$(abspath $<) --verbose
	brew bundle check --file=$(abspath $<) --verbose
.PHONY: bundle

free: Brewfile.free | /usr/local/bin/brew
	brew bundle --file=$(abspath $<) --verbose
	brew bundle check --file=$(abspath $<) --verbose
.PHONY: free

/usr/local/bin/brew:
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
