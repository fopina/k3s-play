#!/bin/sh

cd $(dirname $0)

set -e

# such as --docker
K3S_ARGS="$@"
MASTER=worker1

function install_docker() {
    test "${K3S_ARGS#*docker}" == "$K3S_ARGS" && return 0
    ln=$1
    multipass exec ${ln} -- sh -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
    multipass exec ${ln} -- sh -c 'sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"'
    multipass exec ${ln} -- sudo apt-get -y install docker-ce docker-ce-cli containerd.io
}

function master() {
    NAME=${1:-master}
    install_docker k3s-$NAME
    multipass exec k3s-$NAME -- sudo sh -c "curl -sfL https://get.k3s.io | sh -s -- ${K3S_ARGS}"
}

function worker() {
    NAME=${1:-worker}
    install_docker k3s-$NAME
    multipass exec k3s-$NAME -- sudo sh -c "curl -sfL https://get.k3s.io | K3S_URL=\"https://${MASTER_IP}:6443\" K3S_TOKEN=\"${TOKEN}\" sh -s -- ${K3S_ARGS}"
}

master ${MASTER}

TOKEN=$(multipass exec k3s-${MASTER} sudo cat /var/lib/rancher/k3s/server/node-token)
MASTER_IP=$(multipass info k3s-${MASTER} --format csv | cut -d ',' -f3 | tail -n1)

worker master
worker worker2

multipass exec k3s-${MASTER} -- sudo kubectl config view --raw | sed -e "s/server: .*/server: https:\/\/${MASTER_IP}:6443/g" > .kubeconfig

echo To use local kubectl run:
echo export KUBECONFIG=$(pwd)/.kubeconfig
