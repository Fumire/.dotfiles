all:

$(HOME)/.ssh/authorized_keys:
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi;
	touch $@

add_key: id_rsa.pub $(HOME)/.ssh/authorized_keys
	cat $(word 1,$^) >> $(word 2,$^)
