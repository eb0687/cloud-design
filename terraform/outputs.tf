output "vpc_id" {
  description = "Proposed application VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Proposed public subnet IDs for the load balancer."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Proposed private subnet IDs for workloads and data services."
  value       = aws_subnet.private[*].id
}

output "ecr_repository_urls" {
  description = "Immutable ECR repositories for the six application images."
  value       = { for name, repository in aws_ecr_repository.service : name => repository.repository_url }
}

output "inventory_database_endpoint" {
  description = "Private inventory database endpoint."
  value       = aws_db_instance.inventory.address
}

output "billing_database_endpoint" {
  description = "Private billing database endpoint."
  value       = aws_db_instance.billing.address
}

output "rabbitmq_endpoint" {
  description = "Private Amazon MQ RabbitMQ endpoint."
  value       = aws_mq_broker.rabbitmq.instances[0].endpoints
}

output "cognito_user_pool_id" {
  description = "Cognito user pool for gateway authentication."
  value       = aws_cognito_user_pool.main.id
}

output "gateway_load_balancer_dns" {
  description = "Public HTTPS load balancer DNS name for the API gateway."
  value       = aws_lb.gateway.dns_name
}
