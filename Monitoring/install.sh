#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-.kube/config}"
CHART_VERSION="${CHART_VERSION:-77.5.0}"
export KUBECONFIG="$KUBECONFIG_PATH"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --version "$CHART_VERSION" \
    --values Monitoring/kube-prometheus-stack-values.yaml \
    --wait \
    --timeout 10m

kubectl apply -f Monitoring/service-monitors.yaml
kubectl apply -f Monitoring/prometheus-rules.yaml
kubectl create configmap cloud-design-overview-dashboard \
    --namespace monitoring \
    --from-file=cloud-design-overview.json=Monitoring/dashboards/cloud-design-overview.json \
    --dry-run=client \
    --output=yaml \
    | kubectl label --local -f - grafana_dashboard=1 --output=yaml \
    | kubectl apply -f -

kubectl rollout status deployment/monitoring-grafana -n monitoring --timeout=180s
kubectl rollout status statefulset/prometheus-monitoring-kube-prometheus-prometheus -n monitoring --timeout=180s
