#!/usr/bin/env bash

set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-.kube/config}"
SECRET_NAME="orchestrator-credentials"

if [ -f .env.local ]; then
    # .env.local is ignored and is intended only for local development.
    set -a
    # shellcheck disable=SC1091
    source .env.local
    set +a
fi

required_vars=(
    INVENTORY_POSTGRES_USER
    INVENTORY_POSTGRES_PASSWORD
    BILLING_POSTGRES_USER
    BILLING_POSTGRES_PASSWORD
    BILLING_RABBITMQ_USER
    BILLING_RABBITMQ_PASSWORD
)

for variable in "${required_vars[@]}"; do
    if [ -z "${!variable:-}" ]; then
        printf 'Missing required variable: %s\n' "$variable" >&2
        printf 'Copy .env.example to .env.local and set local values.\n' >&2
        exit 1
    fi
done

kubectl --kubeconfig="$KUBECONFIG_PATH" create secret generic "$SECRET_NAME" \
    --from-literal="INVENTORY_POSTGRES_USER=$INVENTORY_POSTGRES_USER" \
    --from-literal="INVENTORY_POSTGRES_PASSWORD=$INVENTORY_POSTGRES_PASSWORD" \
    --from-literal="BILLING_POSTGRES_USER=$BILLING_POSTGRES_USER" \
    --from-literal="BILLING_POSTGRES_PASSWORD=$BILLING_POSTGRES_PASSWORD" \
    --from-literal="BILLING_RABBITMQ_USER=$BILLING_RABBITMQ_USER" \
    --from-literal="BILLING_RABBITMQ_PASSWORD=$BILLING_RABBITMQ_PASSWORD" \
    --dry-run=client \
    --output=yaml \
    | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f -
