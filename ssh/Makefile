all:

$(HOME)/.ssh/known_hosts:
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi;
	touch $@

add_key: id_rsa.pub $(HOME)/.ssh/known_hosts
	cat $(word 1,$^) >> $(word 2,$^)
