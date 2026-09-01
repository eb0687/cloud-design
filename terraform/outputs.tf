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
