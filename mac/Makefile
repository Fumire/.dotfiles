all: /usr/local/bin/brew
.PHONY += all

start: starting.sh
	sh $<
.PHONY += start

bundle: Brewfile | /usr/local/bin/brew
	brew bundle --file=$(abspath $<)
	brew bundle check --file=$(abspath $<)
.PHONY += bundle

/usr/local/bin/brew:
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
