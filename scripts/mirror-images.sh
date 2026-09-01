#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'Usage: %s <release-tag>\n' "$0" >&2
  exit 64
fi

release_tag=$1
if [[ ! $release_tag =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]]; then
  printf 'Release tag must be a valid Docker image tag.\n' >&2
  exit 64
fi

for command in aws docker jq terraform; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$command" >&2
    exit 69
  fi
done

repository_root=$(git rev-parse --show-toplevel)
terraform_directory="$repository_root/terraform"

if [[ ! -d $terraform_directory ]]; then
  printf 'Terraform directory not found: %s\n' "$terraform_directory" >&2
  exit 66
fi

aws sts get-caller-identity >/dev/null

repository_urls=$(terraform -chdir="$terraform_directory" output -json application_ecr_repository_urls)
applications=(api-gateway-app inventory-app billing-app)
first_repository_url=$(jq -er --arg application "${applications[0]}" '.[$application]' <<< "$repository_urls")
registry=${first_repository_url%%/*}

if [[ $registry =~ \.dkr\.ecr\.([a-z0-9-]+)\.amazonaws\.com$ ]]; then
  aws_region=${BASH_REMATCH[1]}
else
  printf 'Unable to derive the AWS region from ECR registry: %s\n' "$registry" >&2
  exit 65
fi

aws ecr get-login-password --region "$aws_region" |
  docker login --username AWS --password-stdin "$registry"

for application in "${applications[@]}"; do
  source_image="ghcr.io/01-edu/content-$application:latest"
  repository_url=$(jq -er --arg application "$application" '.[$application]' <<< "$repository_urls")
  target_image="$repository_url:$release_tag"

  docker pull "$source_image"
  source_digest=$(docker image inspect --format '{{index .RepoDigests 0}}' "$source_image")
  docker tag "$source_image" "$target_image"
  docker push "$target_image"

  repository_name=${repository_url#*/}
  target_digest=$(aws ecr describe-images \
    --region "$aws_region" \
    --repository-name "$repository_name" \
    --image-ids imageTag="$release_tag" \
    --query 'imageDetails[0].imageDigest' \
    --output text)

  printf '%s\n' "source: $source_digest"
  printf '%s\n' "target: $target_image@$target_digest"
done
