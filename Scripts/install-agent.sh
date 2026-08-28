#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="${MASTER_IP:-192.168.60.10}"
AGENT_IP="${AGENT_IP:-192.168.60.11}"
FLANNEL_IFACE="${FLANNEL_IFACE:-enp0s8}"
TOKEN_FILE="/vagrant/node-token"
K3S_VERSION="${K3S_VERSION:-v1.36.3+k3s1}"

apt-get update
apt-get install -y curl

until [ -f "${TOKEN_FILE}" ]; do
  echo "Waiting for master node token..."
  sleep 5
done

NODE_TOKEN="$(cat "${TOKEN_FILE}")"

curl -sfL https://get.k3s.io -o /tmp/k3s-install.sh

install_attempt=0
until K3S_URL="https://${MASTER_IP}:6443" \
  K3S_TOKEN="${NODE_TOKEN}" \
  INSTALL_K3S_VERSION="${K3S_VERSION}" \
  INSTALL_K3S_EXEC="agent --node-ip=${AGENT_IP} --flannel-iface=${FLANNEL_IFACE}" sh /tmp/k3s-install.sh; do
  install_attempt=$((install_attempt + 1))
  if [ "${install_attempt}" -ge 3 ]; then
    echo "k3s installation failed after 3 attempts" >&2
    exit 1
  fi
  echo "k3s install failed (attempt ${install_attempt}), retrying in 10s..."
  sleep 10
done
