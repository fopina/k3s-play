#!/bin/sh

cd $(dirname $0)

multipass delete swarm-master
multipass delete swarm-worker1
multipass delete swarm-worker2
multipass purge
multipass list
