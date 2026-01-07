# =============================================================================
# Variables - Static Website Example
# =============================================================================

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "account_name" {
  description = "Account name for resource naming"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "mywebsite"
}

variable "domain_name" {
  description = "Domain name for CORS configuration"
  type        = string
  default     = "example.com"
}
