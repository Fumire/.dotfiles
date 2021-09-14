all: $(HOME)/.gnupg/gpg.conf $(HOME)/.gnupg/gpg-agent.conf
.PHONY: all

$(HOME)/.gnupg/gpg.conf: | gpg.conf
	mkdir -p $(@D)
	ln -sf $(abspath $|) $@

$(HOME)/.gnupg/gpg-agent.conf: | gpg-agent.conf
	mkdir -p $(@D)
	ln -sf $(abspath $|) $@
