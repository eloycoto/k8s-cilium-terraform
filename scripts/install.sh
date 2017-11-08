#!/bin/bash

TOKEN=$1
MASTER=$2
HOST=$(hostname)
CILIUM_CONFIG_DIR="/opt/cilium"
ETCD_VERSION="v3.1.0"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

curl -sSL https://get.docker.com/ | sh
systemctl start docker

apt-get install --allow-downgrades -y \
    kubelet kubeadm kubectl kubernetes-cni htop bmon

sudo mkdir -p ${CILIUM_CONFIG_DIR}

function install_etcd(){
    wget -nv https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
    tar -xvf etcd-${ETCD_VERSION}-linux-amd64.tar.gz
    sudo mv etcd-${ETCD_VERSION}-linux-amd64/etcd* /usr/bin/

    sudo tee /etc/systemd/system/etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/bin/etcd --name=cilium --data-dir=/var/etcd/cilium --advertise-client-urls=http://172.16.0.2:9732 --listen-client-urls=http://0.0.0.0:9732 --listen-peer-urls=http://0.0.0.0:9733
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable etcd
    sudo systemctl start etcd
}

sudo mount bpffs /sys/fs/bpf -t bpf

if [[ "${HOST}" == "master" ]]; then
    kubeadm init --token "${TOKEN}"
    mkdir -p /root/.kube
    sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
    sudo chown root:root /root/.kube/config

    sudo cp /etc/kubernetes/admin.conf ${CILIUM_CONFIG_DIR}/kubeconfig
    install_etcd
    # sudo -H kubectl create -f $DIR/rbac.yaml
    sudo -H kubectl create -f $DIR/cilium-ds.yaml
else
    kubeadm join --token=${TOKEN} $MASTER:6443
fi
