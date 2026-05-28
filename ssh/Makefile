all:
.PHONY: all add_key decrypt_key $(HOME)/.ssh/config

$(HOME)/.ssh/authorized_keys:
	mkdir -p $(@D)
	touch $@

add_key: id_rsa.pub $(HOME)/.ssh/authorized_keys
	cat $(word 1,$^) >> $(word 2,$^)

$(HOME)/.ssh/config: | config
	@set -eu; \
	mkdir -p "$(@D)"; \
	if [ -e "$@" ] && [ ! -L "$@" ]; then \
		backup="$@.bak.$$(date +%Y%m%d%H%M%S)"; \
		echo "Backing up $@ to $$backup"; \
		mv "$@" "$$backup"; \
	fi; \
	ln -sfnv "$(abspath $|)" "$@"
	chmod 600 $@

$(HOME)/.ssh/id_%: $(HOME)/Documents/PrivateKeys/id_%.asc
	gpg --decrypt $< > $@
	chmod 400 $@

decrypt_key: $(HOME)/.ssh/id_rsa
