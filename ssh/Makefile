all:
.PHONY: all

$(HOME)/.ssh/authorized_keys:
	mkdir -p $(@D)
	touch $@

add_key: id_rsa.pub $(HOME)/.ssh/authorized_keys
	cat $(word 1,$^) >> $(word 2,$^)
.PHONY: add_key

$(HOME)/.ssh/config: | config
	ln -sf $(abspath $|) $@
	chmod 600 $@

$(HOME)/.ssh/id_%: $(HOME)/Documents/PrivateKeys/id_%.asc
	gpg --decrypt $< > $@
	chmod 400 $@

decrypt_key: $(HOME)/.ssh/id_rsa
.PHONY: decrypt_key
