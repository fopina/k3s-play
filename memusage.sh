#!/bin/sh

for i in k3s-master k3s-worker1 k3s-worker2; do
    echo == $i
    multipass exec $i -- free -h
done
