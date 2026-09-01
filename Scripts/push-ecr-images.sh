#!/usr/bin/env bash

set -euo pipefail

TAG="${1:?Usage: ./Scripts/push-ecr-images.sh <image-tag>}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-$(aws configure get region)}}"
PROJECT_NAME="${PROJECT_NAME:-cloud-design}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_CONTEXT="$(cd "${SCRIPT_DIR}/../Dockerfiles" && pwd)"

if [ -z "$REGION" ]; then
    printf 'Set a default AWS CLI region or provide AWS_REGION.\n' >&2
    exit 1
fi

if [ "$TAG" = "latest" ]; then
    printf 'Use an immutable release tag, not latest.\n' >&2
    exit 1
fi

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password --region "$REGION" \
    | docker login --username AWS --password-stdin "$REGISTRY"

for image in \
    "inventory-db:docker/postgres/Dockerfile" \
    "billing-db:docker/postgres/Dockerfile" \
    "rabbitmq:docker/rabbit-queue/Dockerfile" \
    "inventory-app:apps/inventory/Dockerfile" \
    "billing-app:apps/billing/Dockerfile" \
    "api-gateway-app:apps/gateway/Dockerfile"
do
    name="${image%%:*}"
    dockerfile="${image#*:}"
    destination="${REGISTRY}/${PROJECT_NAME}/${name}:${TAG}"

    docker build --file "${BUILD_CONTEXT}/${dockerfile}" --tag "$destination" "$BUILD_CONTEXT"
    docker push "$destination"
    printf '%s\n' "$destination"
done
