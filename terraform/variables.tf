variable "aws_region" {
  description = "AWS region where the environment will be provisioned."
  type        = string
  default     = "eu-west-3"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier, such as eu-west-3."
  }
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

variable "kubernetes_version" {
  description = "Supported Amazon EKS Kubernetes version selected at deployment time."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must use a major.minor format, such as 1.34."
  }
}

variable "eks_api_allowed_cidrs" {
  description = "Trusted IPv4 CIDR blocks permitted to access the EKS public API endpoint."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.eks_api_allowed_cidrs) > 0 && alltrue([for cidr in var.eks_api_allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "eks_api_allowed_cidrs must contain at least one valid IPv4 CIDR block."
  }
}

variable "eks_node_instance_types" {
  description = "EC2 instance types used by the EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]

  validation {
    condition     = length(var.eks_node_instance_types) > 0
    error_message = "eks_node_instance_types must contain at least one instance type."
  }
}

variable "aws_load_balancer_controller_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version."
  type        = string
  default     = "1.14.1"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.aws_load_balancer_controller_chart_version))
    error_message = "aws_load_balancer_controller_chart_version must use a semantic version, such as 1.14.1."
  }
}

variable "route53_zone_name" {
  description = "Existing public Route 53 hosted-zone name used for API DNS and ACM validation."
  type        = string
  nullable    = false

  validation {
    condition     = length(trim(var.route53_zone_name, ".")) > 0
    error_message = "route53_zone_name must be a non-empty DNS zone name, such as example.com."
  }
}

variable "api_subdomain" {
  description = "Subdomain used for the public API within route53_zone_name."
  type        = string
  default     = "api"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.api_subdomain))
    error_message = "api_subdomain must be a lowercase DNS label."
  }
}

variable "orchestrator_secret_values" {
  description = "Sensitive credentials and database names consumed by the orchestrator workloads."
  type        = map(string)
  sensitive   = true
  nullable    = false

  validation {
    condition = alltrue([
      for key in [
        "INVENTORY_DB_USER",
        "INVENTORY_DB_PASSWORD",
        "INVENTORY_DB_NAME",
        "BILLING_DB_USER",
        "BILLING_DB_PASSWORD",
        "BILLING_DB_NAME",
        "RABBITMQ_USER",
        "RABBITMQ_PASSWORD",
        "RABBITMQ_QUEUE",
      ] : contains(keys(var.orchestrator_secret_values), key)
    ])
    error_message = "orchestrator_secret_values must contain every required database and RabbitMQ key."
  }
}

variable "cognito_domain_prefix" {
  description = "Globally unique Cognito hosted-domain prefix for the API authentication flow."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.cognito_domain_prefix))
    error_message = "cognito_domain_prefix must be a lowercase DNS label."
  }
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention period for EKS control-plane and application logs."
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365], var.cloudwatch_log_retention_days)
    error_message = "cloudwatch_log_retention_days must be a supported CloudWatch retention period."
  }
}

variable "aws_for_fluent_bit_chart_version" {
  description = "AWS for Fluent Bit Helm chart version used for application log forwarding."
  type        = string
  nullable    = false
}

variable "metrics_server_chart_version" {
  description = "Metrics Server Helm chart version used by Kubernetes HPAs."
  type        = string
  nullable    = false
}

variable "cluster_autoscaler_chart_version" {
  description = "Cluster Autoscaler Helm chart version compatible with the selected EKS Kubernetes version."
  type        = string
  nullable    = false
}
