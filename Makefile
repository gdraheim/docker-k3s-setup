MANIFESTS2=/etc/rancher/manifests2
K3SERVICE=k3s.service
DOCKERGROUP=docker

help:
	: make install
	: make uninstall

install:
	test 0 = `id -u`
	test -d $(MANIFESTS2) || mkdir -v $(MANIFESTS2)
	cp -v manifests/*.yaml $(MANIFESTS2)
	cp -v manifests/Makefile $(MANIFESTS2)/Makefile
	cd $(MANIFESTS2) && $(MAKE)
	cp -v docker-stop-k3s /usr/local/bin/docker-stop-k3s
	cp -v $(K3SERVICE) /etc/systemd/system/
	sed -i -e "/chgrp docker/chgrp $(DOCKERGROUP)/" /etc/systemd/system/$(K3SERVICE)
	systemctl daemon-reload
	cp -v k3s.sudoers /etc/sudoers.d/$(K3SERVICE:.service=)
	sed -i -e "s/%docker/%$(DOCKERGROUP)/" /etc/sudoers.d/$(K3SERVICE:.service=)
	sed -i -e "s/ k3s[a-z-]*/ $(K3SERVICE:.service=)/" /etc/sudoers.d/$(K3SERVICE:.service=)
	cp -v kube /usr/local/bin/kube
	systemctl cat $(K3SERVICE) | head

uninstall:
	test 0 = `id -u`
	test ! -f /etc/sudoers.d/$(K3SERVICE:.service=) || rm -v /etc/sudoers.d/$(K3SERVICE:.service=)
	test ! -f /etc/systemd/system/$(K3SERVICE) || \
	   (rm -v /etc/systemd/system/$(K3SERVICE) && systemctl daemon-reload)
	test ! -f /usr/local/bin/docker-stop-k3s || rm -v /usr/local/bin/docker-stop-k3s
	test ! -f /usr/local/bin/kube || rm -v /usr/local/bin/kube
	for yaml in /var/lib/rancher/k3s/server/manifests/*.yaml; do : \
	; if readlink $$yaml | grep $(MANIFESTS2); then rm -v $$yaml; fi; done 
	test ! -f $(MANIFESTS2)/ingress-nginx.yaml || rm -v $(MANIFESTS2)/*.yaml
	test ! -f $(MANIFESTS2)/Makefile || rm -v $(MANIFESTS2)/Makefile
	test ! -d $(MANIFESTS2) || test 1 -lt "`du -s --inodes $(MANIFESTS2) | cut -f 1`" || rmdir -v $(MANIFESTS2)

