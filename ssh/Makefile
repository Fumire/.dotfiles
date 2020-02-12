all:
	ssh-add -c

$(HOME)/.ssh/authorized_keys:
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi;
	touch $@

add_key: id_rsa.pub $(HOME)/.ssh/authorized_keys
	cat $(word 1,$^) >> $(word 2,$^)

$(HOME)/.ssh/%: $(HOME)/Documents/PrivateKeys/%.asc
	gpg --decrypt $< > $@
	chmod 400 $@

decrypt_key: $(HOME)/.ssh/id_rsa $(HOME)/.ssh/id_dsa
