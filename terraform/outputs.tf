output "vpc_id" {
  description = "Application VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ALB."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by ECS, RDS, and Amazon MQ."
  value       = aws_subnet.private[*].id
}

output "ecr_repository_urls" {
  description = "Immutable ECR repositories for the three application images."
  value       = { for name, repository in aws_ecr_repository.service : name => repository.repository_url }
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_names" {
  description = "ECS service names for the three application workloads."
  value = {
    gateway   = aws_ecs_service.gateway.name
    inventory = aws_ecs_service.inventory.name
    billing   = aws_ecs_service.billing.name
  }
}

output "inventory_database_endpoint" {
  description = "Private inventory RDS endpoint."
  value       = aws_db_instance.inventory.address
}

output "billing_database_endpoint" {
  description = "Private billing RDS endpoint."
  value       = aws_db_instance.billing.address
}

output "rabbitmq_endpoint" {
  description = "Private Amazon MQ RabbitMQ endpoint."
  value       = aws_mq_broker.rabbitmq.instances[0].endpoints
}

output "cognito_user_pool_id" {
  description = "Cognito user pool used by the ALB authentication action."
  value       = aws_cognito_user_pool.main.id
}

output "gateway_url" {
  description = "Public HTTPS URL for the API gateway."
  value       = "https://${var.domain_name}"
}

output "gateway_load_balancer_dns" {
  description = "ALB DNS name for the API gateway."
  value       = aws_lb.gateway.dns_name
}
