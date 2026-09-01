output "vpc_id" {
  description = "ID of the VPC hosting the application environment."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets for internet-facing load balancers."
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets for EKS nodes and workloads."
  value       = values(aws_subnet.private)[*].id
}

output "alb_security_group_id" {
  description = "Security group ID for the future public application load balancer."
  value       = aws_security_group.alb.id
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for the future EKS managed node group."
  value       = aws_security_group.eks_nodes.id
}

output "application_ecr_repository_urls" {
  description = "Repository URLs used to publish the application container images."
  value       = { for name, repository in aws_ecr_repository.application : name => repository.repository_url }
}

output "eks_cluster_name" {
  description = "Name used by AWS CLI and kubectl to access the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API endpoint for the EKS cluster."
  value       = aws_eks_cluster.this.endpoint
}

output "api_domain_name" {
  description = "Public hostname assigned to the API gateway."
  value       = local.api_domain_name
}

output "api_certificate_arn" {
  description = "Validated ACM certificate ARN for the API Application Load Balancer."
  value       = aws_acm_certificate_validation.api.certificate_arn
}

output "api_load_balancer_dns_name" {
  description = "AWS-generated DNS name for the API Application Load Balancer."
  value       = data.aws_lb.api.dns_name
}
