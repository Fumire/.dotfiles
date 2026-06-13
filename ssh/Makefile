SSH_KEY_CANDIDATES := id_ed25519 id_rsa

all:
.PHONY: all add_key decrypt_key $(HOME)/.ssh/config

$(HOME)/.ssh/authorized_keys:
	mkdir -p $(@D)
	touch $@

add_key: $(HOME)/.ssh/authorized_keys
	@set -eu; \
	for key in $(SSH_KEY_CANDIDATES); do \
		if [ -f "$$key.pub" ]; then \
			cat "$$key.pub" >> "$<"; \
			echo "Appended $$key.pub to $<"; \
			exit 0; \
		fi; \
	done; \
	echo "No public SSH key found; expected id_ed25519.pub or id_rsa.pub" >&2; \
	exit 1

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
	mkdir -p "$(@D)"
	gpg --decrypt "$<" > "$@"
	chmod 400 "$@"

decrypt_key:
	@set -eu; \
	for key in $(SSH_KEY_CANDIDATES); do \
		if [ -f "$(HOME)/Documents/PrivateKeys/$$key.asc" ]; then \
			$(MAKE) "$(HOME)/.ssh/$$key"; \
			exit 0; \
		fi; \
	done; \
	echo "No encrypted SSH key found; expected ~/Documents/PrivateKeys/id_ed25519.asc or id_rsa.asc" >&2; \
	exit 1
