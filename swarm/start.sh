#!/bin/sh

cd $(dirname $0)

set -e

function install_docker() {
    NAME=$1
    multipass exec ${NAME} -- sh -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
    multipass exec ${NAME} -- sh -c 'sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"'
    multipass exec ${NAME} -- sudo apt-get -y install docker-ce docker-ce-cli containerd.io
}

function master() {
    multipass launch --name swarm-master --mem 1G --disk 5G bionic || true
    install_docker swarm-master
    multipass exec swarm-master -- sudo docker swarm init
}

function worker() {
    NAME=${1:-worker}
    multipass launch --name swarm-$NAME --mem 1G --disk 5G bionic || true
    install_docker swarm-$NAME
    multipass exec swarm-master -- sudo docker swarm join --token ${TOKEN} ${MASTER_IP}
}

master

TOKEN=$(multipass exec swarm-master -- sudo docker swarm join-token -q worker)
MASTER_IP=$(multipass info swarm-master --format csv | cut -d ',' -f3 | tail -n1)

worker worker1
worker worker2
