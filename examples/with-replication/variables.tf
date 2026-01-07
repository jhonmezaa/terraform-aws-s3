variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "replica_region" {
  description = "Replica AWS region"
  type        = string
  default     = "us-west-2"
}

variable "primary_region_prefix" {
  description = "Region prefix for primary region"
  type        = string
  default     = "ause1"
}

variable "replica_region_prefix" {
  description = "Region prefix for replica region"
  type        = string
  default     = "usw2"
}

variable "account_name" {
  description = "Account name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "replicated"
}
