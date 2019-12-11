all: /usr/local/bin/brew
.PHONY += all

bundle: Brewfile
	brew bundle --file=$(abspath $<)
.PHONY += bundle

/usr/local/bin/brew:
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
