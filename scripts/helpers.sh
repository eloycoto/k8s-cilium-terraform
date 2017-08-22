#!/bin/bash

cilium_get_status() {
    for cilium in $(kubectl -n kube-system get pods --selector=k8s-app=cilium --output=jsonpath={.items..metadata.name}); do
        echo "===============\n$cilium\n==============="
        kubectl -n kube-system exec $cilium cilium status
        kubectl -n kube-system exec $cilium cilium service list
    done
}

