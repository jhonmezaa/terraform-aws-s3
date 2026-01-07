# =============================================================================
# Variables - Simple Example
# =============================================================================

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "account_name" {
  description = "Account name for resource naming (e.g., prod, dev, staging)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "example"
}
