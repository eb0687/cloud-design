variable "aws_region" {
  description = "AWS region where the environment will be provisioned."
  type        = string
  default     = "eu-west-3"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier, such as eu-west-3."
  }
}

variable "aws_profile" {
  description = "Optional AWS CLI profile to use when applying this configuration."
  type        = string
  default     = null
  nullable    = true
}

variable "project_name" {
  description = "Short project identifier included in AWS resource names and tags."
  type        = string
  default     = "cloud-design"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-32 lowercase letters, numbers, and hyphens; it must start and end with a letter or number."
  }
}

variable "environment" {
  description = "Deployment environment identifier, such as dev or production."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.environment))
    error_message = "environment must be 2-15 lowercase letters, numbers, and hyphens, beginning with a letter."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Exactly two Availability Zones used by the VPC subnets."
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]

  validation {
    condition     = length(var.availability_zones) == 2 && length(distinct(var.availability_zones)) == 2
    error_message = "availability_zones must contain exactly two distinct Availability Zones."
  }
}

variable "public_subnet_cidrs" {
  description = "IPv4 CIDR blocks for the internet-facing load balancer subnets."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "public_subnet_cidrs must contain two valid IPv4 CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "IPv4 CIDR blocks for the EKS node and workload subnets."
  type        = list(string)
  default     = ["10.0.16.0/20", "10.0.32.0/20"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2 && alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "private_subnet_cidrs must contain two valid IPv4 CIDR blocks."
  }
}

variable "allowed_ingress_cidrs" {
  description = "IPv4 CIDR blocks permitted to access the public load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.allowed_ingress_cidrs : can(cidrnetmask(cidr))])
    error_message = "allowed_ingress_cidrs must contain valid IPv4 CIDR blocks."
  }
}

variable "api_gateway_port" {
  description = "TCP port exposed by the API gateway application container."
  type        = number
  default     = 3000

  validation {
    condition     = var.api_gateway_port >= 1 && var.api_gateway_port <= 65535
    error_message = "api_gateway_port must be between 1 and 65535."
  }
}
