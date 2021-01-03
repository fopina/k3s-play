quickly setup local k3s playground (using multipass for VMs)

```
./start.sh
export KUBECONFIG=$(pwd)/.kubeconfig
kubectl apply -f manifest.yaml
```
