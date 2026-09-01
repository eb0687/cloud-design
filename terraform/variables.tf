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
