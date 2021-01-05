#!/bin/sh

for i in swarm-master swarm-worker1 swarm-worker2; do
    echo == $i
    multipass exec $i -- free -h
done
