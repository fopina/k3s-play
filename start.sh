#!/bin/sh

cd $(dirname $0)

function master() {
    multipass launch --name k3s-master --mem 1G --disk 5G bionic
    multipass exec k3s-master -- sh -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
    multipass exec k3s-master -- sh -c 'sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"'
    multipass exec k3s-master -- sudo apt-get install docker-ce docker-ce-cli containerd.io
    multipass exec k3s-master -- sudo sh -c "curl -sfL https://get.k3s.io | sh -s --docker"
}

function worker() {
    NAME=${1:-worker}
    multipass launch --name k3s-$NAME --mem 1G --disk 5G bionic
    multipass exec k3s-$NAME -- sh -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
    multipass exec k3s-master -- sh -c 'sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"'
    multipass exec k3s-master -- sudo apt-get install docker-ce docker-ce-cli containerd.io
    multipass exec k3s-$NAME -- sudo sh -c "curl -sfL https://get.k3s.io | K3S_URL=\"https://${MASTER_IP}:6443\" K3S_TOKEN=\"${TOKEN}\" sh - --docker"
}

TOKEN=$(multipass exec k3s-master sudo cat /var/lib/rancher/k3s/server/node-token)
MASTER_IP=$(multipass info k3s-master --format csv | cut -d ',' -f3 | tail -n1)

master
worker worker1
worker worker2

multipass exec k3s-master -- sudo kubectl config view --raw | sed -e "s/server: .*/server: https:\/\/${MASTER_IP}:6443/g" > .kubeconfig

echo To use local kubectl run:
echo export KUBECONFIG=$(pwd)/.kubeconfig