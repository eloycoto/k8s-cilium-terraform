#!/bin/bash

cilium_get_status() {
    # return all cilium status from all pods.
    for cilium in $(kubectl -n kube-system get pods --selector=k8s-app=cilium --output=jsonpath={.items..metadata.name}); do
        echo "===============${cilium}==============="
        kubectl -n kube-system exec $cilium cilium status
    done
}

cilium_get_tunnels() {
    # return all cilium status from all pods.
    for cilium in $(kubectl -n kube-system get pods --selector=k8s-app=cilium --output=jsonpath={.items..metadata.name}); do
        echo "===============${cilium}==============="
        kubectl -n kube-system exec $cilium cilium bpf tunnel list
    done
}

cilium_get_services() {
    # return all cilium status from all pods.
    for cilium in $(kubectl -n kube-system get pods --selector=k8s-app=cilium --output=jsonpath={.items..metadata.name}); do
        echo "===============${cilium}==============="
        kubectl -n kube-system exec $cilium cilium service list
    done
}

get_physical_interfaces() {
    # print all physical interfaces
    find /sys/class/net -type l -not -lname '*virtual*' -printf '%f\n'
}

