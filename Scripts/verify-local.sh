#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-.kube/config}"
export KUBECONFIG="$KUBECONFIG_PATH"

if [ ! -f "$KUBECONFIG_PATH" ]; then
    printf 'Kubeconfig not found at %s. Run ./orchestrator.sh create first.\n' "$KUBECONFIG_PATH" >&2
    exit 1
fi

kubectl wait --for=condition=Ready node --all --timeout=180s
kubectl get nodes -o wide
kubectl get pods,svc,pvc,hpa
kubectl get networkpolicy

for workload in inventory-app billing-app api-gateway-app; do
    kubectl rollout status "deployment/$workload" --timeout=180s 2>/dev/null || \
        kubectl rollout status "statefulset/$workload" --timeout=180s
done

kubectl get endpoints inventory-app billing-app api-gateway-app rabbitmq inventory-db billing-db
