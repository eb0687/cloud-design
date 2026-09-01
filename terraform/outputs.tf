output "cluster_name" {
  description = "EKS cluster name for aws eks update-kubeconfig."
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Public EKS Kubernetes API endpoint."
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded EKS Kubernetes API certificate authority data."
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "node_group_name" {
  description = "Minimal managed EKS node group name."
  value       = aws_eks_node_group.main.node_group_name
}

output "public_subnet_ids" {
  description = "Public subnet IDs for EKS worker nodes and Kubernetes load balancers."
  value       = aws_subnet.public[*].id
}

output "ecr_repository_urls" {
  description = "Immutable ECR repositories for the six application images."
  value       = { for name, repository in aws_ecr_repository.service : name => repository.repository_url }
}
