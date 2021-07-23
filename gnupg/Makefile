all: $(HOME)/.gnupg/gpg.conf $(HOME)/.gnupg/gpg-agent.conf
.PHONY: all

$(HOME)/.gnupg:
	mkdir -p $@

$(HOME)/.gnupg/gpg.conf: gpg.conf | $(HOME)/.gnupg
	ln -sf $(abspath $<) $@

$(HOME)/.gnupg/gpg-agent.conf: gpg-agent.conf | $(HOME)/.gnupg
	ln -sf $(abspath $<) $@
