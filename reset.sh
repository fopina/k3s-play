#!/bin/sh

cd $(dirname $0)

multipass delete k3s-master
multipass delete k3s-worker1
multipass delete k3s-worker2
multipass purge
multipass list
