# Using docker as backend for k3s

That is very easy. Just provide "--docker" as the argument.
The only problem is that the default k3s-server.service loads
an enviromentfile /etc/rancher/k3s/server.conf but it can not 
expand its values.

Since we do also want to ensure that the docker.service is started
before, it is a good idea to copy k3s.service to a new file named
k3s.service

Interestingly, when stopping the "k3s server" via systemctl-stop
it does not kill the docker containers started by k3s. So we have
added a script docker-stop-k3s which gets called automatically
via ExecStopPost

# Directly using k3s as a non-root user

The default chmod bits for /etc/rancher/k3s/k3s.yaml are 0400.

Instead "k3s server" should get --write-kubeconfig-mode=0640

But even this is not working all the time, so some ExecStartPost are added

    ExecStartPost=/bin/chgrp docker /etc/rancher/k3s/k3s.yaml
    ExecStartPost=/bin/chmod 0640 /etc/rancher/k3s/k3s.yaml

Additionally, some /etc/sudoers.d/k3s is installed, so that users
in the "docker" unix group can start/stop k3s containers.

# Using nginx as the frontend for k3s

Forget about other how-to ... the real one comes from Suse.

* https://www.suse.com/support/kb/doc/?id=000020082

Of course, make sure to have added `--no-deploy=traefik` to "k3s server".

But instead of kubectl, you can use a helm chart reference in k3s.
Actually traefik is deployed via its helm chart in k3s, have a look at

    sudo head /var/lib/rancher/k3s/server/manifests/traefik.yaml

When the no-deploy=traefik is in place, that file is ignored. Instead
we deploy the ingress-nginx.yaml which comes from that suse ticket.

# Using metallb to expose services

Again, make sure to have added `--no-deploy=servicelb` to "k3s server"

Since we are installing both nginx and metallb, we want to make sure
that metallb gets run before nginx. That's why there are two files here:

    manifests/setup-10-metallb-system.yaml
    manifests/setup-20-ingress-nginx.yaml

