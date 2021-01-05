#!/bin/sh

cd $(dirname $0)

set -e

K3S_ARGS=""
#K3S_ARGS="--docker"

function install_docker() {
    test "${K3S_ARGS#*docker}" == "$K3S_ARGS" && return 0
    NAME=$1
    multipass exec ${NAME} -- sh -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
    multipass exec ${NAME} -- sh -c 'sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"'
    multipass exec ${NAME} -- sudo apt-get -y install docker-ce docker-ce-cli containerd.io
}

function master() {
    multipass launch --name k3s-master --mem 1G --disk 5G bionic || true
    install_docker k3s-master
    multipass exec k3s-master -- sudo sh -c "curl -sfL https://get.k3s.io | sh -s -- ${K3S_ARGS}"
}

function worker() {
    NAME=${1:-worker}
    multipass launch --name k3s-$NAME --mem 1G --disk 5G bionic || true
    install_docker k3s-$NAME
    multipass exec k3s-$NAME -- sudo sh -c "curl -sfL https://get.k3s.io | K3S_URL=\"https://${MASTER_IP}:6443\" K3S_TOKEN=\"${TOKEN}\" sh -s -- ${K3S_ARGS}"
}

master

TOKEN=$(multipass exec k3s-master sudo cat /var/lib/rancher/k3s/server/node-token)
MASTER_IP=$(multipass info k3s-master --format csv | cut -d ',' -f3 | tail -n1)

worker worker1
worker worker2

multipass exec k3s-master -- sudo kubectl config view --raw | sed -e "s/server: .*/server: https:\/\/${MASTER_IP}:6443/g" > .kubeconfig

echo To use local kubectl run:
echo export KUBECONFIG=$(pwd)/.kubeconfig
