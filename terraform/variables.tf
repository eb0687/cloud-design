variable "aws_region" {
  description = "AWS region for the EKS deployment."
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Prefix applied to AWS resource names and the EKS cluster name."
  type        = string
  default     = "cloud-design"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR range for the EKS VPC."
  type        = string
  default     = "10.40.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR range."
  }
}

variable "availability_zones" {
  description = "Availability zones for the EKS control plane and public worker subnets."
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones are required by EKS."
  }
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.34"
}

variable "node_instance_type" {
  description = "Instance type for the minimal managed EKS node group."
  type        = string
  default     = "t3.small"
}
