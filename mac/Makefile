all: /usr/local/bin/brew
.PHONY += all

start: starting.sh
	sh $<

bundle: Brewfile
	brew bundle --file=$(abspath $<)
.PHONY += bundle

/usr/local/bin/brew:
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
