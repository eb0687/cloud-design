#!/usr/bin/env bash

set -euo pipefail

PROVIDER="${VAGRANT_PROVIDER:-virtualbox}"
KUBECONFIG_PATH="${KUBECONFIG:-.kube/config}"

usage() {
    cat <<USAGE
Usage: ./orchestrator.sh <command>

Commands:
  create    Create and provision the K3s cluster
  start     Start the K3s cluster
  stop      Stop the K3s cluster
  deploy    Apply Kubernetes manifests
  secret    Create/update the local Kubernetes Secret
  verify    Run local deployment checks
  status    Show Vagrant VM status
  nodes     Show Kubernetes nodes
  pods      Show Kubernetes pods across all namespaces
  destroy   Destroy the Vagrant VMs
  clean     Destroy VMs and remove local generated state

Environment overrides:
  MASTER_IP=192.168.60.10
  AGENT_IP=192.168.60.11
  VAGRANT_PROVIDER=virtualbox
  KUBECONFIG=.kube/config
USAGE
}

require_kubeconfig() {
    if [ ! -f "$KUBECONFIG_PATH" ]; then
        echo "kubeconfig not found at ${KUBECONFIG_PATH}"
        echo "Run './orchestrator.sh create' first."
        exit 1
    fi
}

wait_for_nodes() {
    require_kubeconfig
    KUBECONFIG="$KUBECONFIG_PATH" kubectl wait --for=condition=Ready node --all --timeout=180s
}

deploy_manifests() {
    wait_for_nodes
    KUBECONFIG="$KUBECONFIG_PATH" kubectl apply -f Manifests
}

command="${1:-}"

case "$command" in
    create)
        vagrant up --provider="$PROVIDER"
        deploy_manifests
        echo "cluster created"
        ;;
    start)
        vagrant up --provider="$PROVIDER"
        deploy_manifests
        echo "cluster started"
        ;;
    stop)
        vagrant halt
        echo "cluster stopped"
        ;;
    status)
        vagrant status
        ;;
    nodes)
        require_kubeconfig
        KUBECONFIG="$KUBECONFIG_PATH" kubectl get nodes -o wide
        ;;
    pods)
        require_kubeconfig
        KUBECONFIG="$KUBECONFIG_PATH" kubectl get pods -A
        ;;
    deploy)
        deploy_manifests
        echo "infrastructure deployed"
        ;;
    secret)
        require_kubeconfig
        ./Scripts/create-local-secret.sh
        ;;
    verify)
        ./Scripts/verify-local.sh
        ;;
    destroy)
        vagrant destroy -f
        echo "cluster destroyed"
        ;;
    clean)
        vagrant destroy -f
        rm -rf .vagrant .kube node-token
        echo "cluster destroyed and local generated state cleaned"
        ;;
    -h|--help|help|"")
        usage
        ;;
    *)
        echo "Unknown command: ${command}"
        echo
        usage
        exit 1
        ;;
esac
