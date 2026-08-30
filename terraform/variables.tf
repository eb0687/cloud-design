variable "aws_region" {
  description = "AWS region for the proposed deployment."
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Prefix applied to proposed AWS resource names."
  type        = string
  default     = "cloud-design"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR range for the proposed private network."
  type        = string
  default     = "10.40.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR range."
  }
}

variable "availability_zones" {
  description = "Two availability zones for the high-level design."
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones are required for the design."
  }
}

variable "database_username" {
  description = "Admin username for the proposed private PostgreSQL instances. Supply via an uncommitted tfvars file."
  type        = string
  sensitive   = true
}

variable "database_password" {
  description = "Admin password for the proposed private PostgreSQL instances. Supply via an uncommitted tfvars file."
  type        = string
  sensitive   = true
}

variable "mq_username" {
  description = "Username for the proposed private RabbitMQ broker. Supply via an uncommitted tfvars file."
  type        = string
  sensitive   = true
}

variable "mq_password" {
  description = "Password for the proposed private RabbitMQ broker. Supply via an uncommitted tfvars file."
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Fully qualified public API domain name managed in Route 53."
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for domain_name."
  type        = string
}

variable "gateway_image_tag" {
  description = "Immutable ECR tag for the gateway image."
  type        = string
  default     = "monitoring-5"
}

variable "inventory_image_tag" {
  description = "Immutable ECR tag for the inventory image."
  type        = string
  default     = "monitoring-5"
}

variable "billing_image_tag" {
  description = "Immutable ECR tag for the billing image."
  type        = string
  default     = "monitoring-5"
}
