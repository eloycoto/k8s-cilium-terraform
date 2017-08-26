# Running Cilium on Kuberneters

This tutorial will walk you through deploying a three nodes Cilium cluster on
Kubernetes.

## Overview

- One k8s master node
- Three k8s nodes running the cilium daemonset


## Prerequisites

- Google Cloud console installed.
- Terraform >= v0.10.2 installed.
- Google service account json file.
- Google compute engine keys created on ~/.ssh/


## Usage

Clone this repo

```
git clone https://github.com/eloycoto/k8s-cilium-terraform.git
cd k8s-cilium-terraform
```

Create the instances and networking on GCP

```
terraform init
terraform apply \
    --var private_key_path="~/.ssh/google_compute_engine" \
    --var project="k8s-cilium" \
    --var credentials="./account.json"
```


The following variables are set by default, but you can change as you need:

- machine_type: instance type for vms, default n1-standard-1
- nodes: Number of nodes for k8s cluster. Default 3
- region: Region to run the cluster, default europe-west1
- token: kubernetes auth token.
- zone: zone to run the cluster, default europe-west-1b


## Verification

When the terraform finish, you can login into the master node using the follwing
command:

```
gcloud compute ssh master
```

When you get into the server, you can get the kubernetes cluster status with the
following commands:

```
root@master:/home/ecoto# kubectl get nodes
NAME      STATUS    AGE       VERSION
master    Ready     12m       v1.7.4
node-0    Ready     10m       v1.7.4
node-1    Ready     10m       v1.7.4
node-2    Ready     2m        v1.7.4
root@master:/home/ecoto# kubectl get pods -n kube-system -o wide
NAME                             READY     STATUS    RESTARTS   AGE       IP            NODE
cilium-0m1gb                     1/1       Running   0          12m       172.16.0.2    master
cilium-6cgtp                     0/1       Running   0          2m        172.16.0.5    node-2
cilium-f52kj                     1/1       Running   0          11m       172.16.0.4    node-0
cilium-w17jt                     1/1       Running   0          11m       172.16.0.3    node-1
etcd-master                      1/1       Running   0          12m       172.16.0.2    master
kube-apiserver-master            1/1       Running   0          12m       172.16.0.2    master
kube-controller-manager-master   1/1       Running   0          12m       172.16.0.2    master
kube-dns-2425271678-6cpm2        3/3       Running   0          13m       10.2.42.252   master
kube-proxy-5xs82                 1/1       Running   0          13m       172.16.0.2    master
kube-proxy-g14zr                 1/1       Running   0          11m       172.16.0.3    node-1
kube-proxy-kwc0r                 1/1       Running   0          2m        172.16.0.5    node-2
kube-proxy-qbpb8                 1/1       Running   0          11m       172.16.0.4    node-0
kube-scheduler-master            1/1       Running   0          12m       172.16.0.2    master
```

To know the cilium status you need to execute the following commands:

**Cilium Status**

```
    for cilium in $(kubectl -n kube-system get pods --selector=k8s-app=cilium --output=jsonpath={.items..metadata.name}); do
        echo "===============${cilium}==============="
        kubectl -n kube-system exec $cilium cilium status
    done
```

Example output:

```
===============cilium-0m1gb===============
Allocated IPv4 addresses:
 10.2.28.238
 10.2.42.252
 10.2.247.232
Allocated IPv6 addresses:
 f00d::ac10:2:0:1
 f00d::ac10:2:0:ad
 f00d::ac10:2:0:8ad6
KVStore:            Ok   Etcd: http://172.16.0.2:6666 - (Leader) 3.1.0
ContainerRuntime:   Ok
Kubernetes:         Ok   OK
Cilium:             Ok   OK
===============cilium-6cgtp===============
Allocated IPv4 addresses:
 10.5.28.238
 10.5.247.232
Allocated IPv6 addresses:
 f00d::ac10:5:0:1
 f00d::ac10:5:0:8ad6
KVStore:            Ok   Etcd: http://172.16.0.2:6666 - (Leader) 3.1.0
ContainerRuntime:   Ok
Kubernetes:         Ok   OK
Cilium:             Ok   OK
===============cilium-f52kj===============
Allocated IPv4 addresses:
 10.4.28.238
 10.4.247.232
Allocated IPv6 addresses:
 f00d::ac10:4:0:1
 f00d::ac10:4:0:8ad6
KVStore:            Ok   Etcd: http://172.16.0.2:6666 - (Leader) 3.1.0
ContainerRuntime:   Ok
Kubernetes:         Ok   OK
Cilium:             Ok   OK
===============cilium-w17jt===============
Allocated IPv4 addresses:
 10.3.28.238
 10.3.247.232
Allocated IPv6 addresses:
 f00d::ac10:3:0:1
 f00d::ac10:3:0:8ad6
KVStore:            Ok   Etcd: http://172.16.0.2:6666 - (Leader) 3.1.0
ContainerRuntime:   Ok
Kubernetes:         Ok   OK
Cilium:             Ok   OK
```


**Cilium tunnel list**

```
    for cilium in $(kubectl -n kube-system get pods --selector=k8s-app=cilium --output=jsonpath={.items..metadata.name}); do
        echo "===============${cilium}==============="
        kubectl -n kube-system exec $cilium cilium bpf tunnel list
    done
```

Example output
```
===============cilium-0m1gb===============
f00d::ac10:4:0:0     172.16.0.4
10.2.0.0             172.16.0.2
f00d::ac10:5:0:0     172.16.0.5
10.5.0.0             172.16.0.5
10.4.0.0             172.16.0.4
f00d::ac10:3:0:0     172.16.0.3
10.3.0.0             172.16.0.3
f00d::ac10:2:0:0     172.16.0.2
===============cilium-6cgtp===============
f00d::ac10:4:0:0     172.16.0.4
10.2.0.0             172.16.0.2
f00d::ac10:5:0:0     172.16.0.5
10.5.0.0             172.16.0.5
10.4.0.0             172.16.0.4
f00d::ac10:3:0:0     172.16.0.3
10.3.0.0             172.16.0.3
f00d::ac10:2:0:0     172.16.0.2
===============cilium-f52kj===============
f00d::ac10:4:0:0     172.16.0.4
10.2.0.0             172.16.0.2
f00d::ac10:5:0:0     172.16.0.5
10.5.0.0             172.16.0.5
10.4.0.0             172.16.0.4
f00d::ac10:3:0:0     172.16.0.3
10.3.0.0             172.16.0.3
f00d::ac10:2:0:0     172.16.0.2
===============cilium-w17jt===============
f00d::ac10:4:0:0     172.16.0.4
10.2.0.0             172.16.0.2
f00d::ac10:5:0:0     172.16.0.5
10.5.0.0             172.16.0.5
10.4.0.0             172.16.0.4
f00d::ac10:3:0:0     172.16.0.3
10.3.0.0             172.16.0.3
f00d::ac10:2:0:0     172.16.0.2
```

**Cilium services list**
```
    for cilium in $(kubectl -n kube-system get pods --selector=k8s-app=cilium --output=jsonpath={.items..metadata.name}); do
        echo "===============${cilium}==============="
        kubectl -n kube-system exec $cilium cilium service list
    done
```


Example output
```
===============cilium-0m1gb===============
ID   Frontend            Backend
1    10.96.0.1:443       1 => 172.16.0.2:6443
2    10.96.0.10:53       1 => 10.2.42.252:53
3    10.109.204.101:80   1 => 10.3.15.138:5000
                         2 => 10.4.15.138:5000
                         3 => 10.5.114.197:5000
===============cilium-6cgtp===============
ID   Frontend            Backend
1    10.96.0.1:443       1 => 172.16.0.2:6443
2    10.96.0.10:53       1 => 10.2.42.252:53
3    10.109.204.101:80   1 => 10.3.15.138:5000
                         2 => 10.4.15.138:5000
                         3 => 10.5.114.197:5000
===============cilium-f52kj===============
ID   Frontend            Backend
1    10.96.0.1:443       1 => 172.16.0.2:6443
2    10.96.0.10:53       1 => 10.2.42.252:53
3    10.109.204.101:80   1 => 10.3.15.138:5000
                         2 => 10.4.15.138:5000
                         3 => 10.5.114.197:5000
===============cilium-w17jt===============
ID   Frontend            Backend
1    10.96.0.1:443       1 => 172.16.0.2:6443
2    10.96.0.10:53       1 => 10.2.42.252:53
3    10.109.204.101:80   1 => 10.3.15.138:5000
                         2 => 10.4.15.138:5000
                         3 => 10.5.114.197:5000
```



## Cleanup

```
terraform destroy \
    --var private_key_path="~/.ssh/google_compute_engine"
    --var project="k8s-cilium"
    --var credentials="./account.json"
```
