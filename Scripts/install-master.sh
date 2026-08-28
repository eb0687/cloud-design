#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="${MASTER_IP:-192.168.60.10}"
FLANNEL_IFACE="${FLANNEL_IFACE:-enp0s8}"
K3S_VERSION="${K3S_VERSION:-v1.36.3+k3s1}"

apt-get update
apt-get install -y curl

curl -sfL https://get.k3s.io -o /tmp/k3s-install.sh

install_attempt=0
until INSTALL_K3S_VERSION="${K3S_VERSION}" INSTALL_K3S_EXEC="server \
   --node-ip=${MASTER_IP} \
   --advertise-address=${MASTER_IP} \
   --flannel-iface=${FLANNEL_IFACE} \
   --write-kubeconfig-mode=644" sh /tmp/k3s-install.sh; do
  install_attempt=$((install_attempt + 1))
  if [ "${install_attempt}" -ge 3 ]; then
    echo "k3s installation failed after 3 attempts" >&2
    exit 1
  fi
  echo "k3s install failed (attempt ${install_attempt}), retrying in 10s..."
  sleep 10
done

mkdir -p /vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /vagrant/.kube/config
sed -i "s/127.0.0.1/${MASTER_IP}/g" /vagrant/.kube/config

cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token
