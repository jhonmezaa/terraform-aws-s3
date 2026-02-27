# =============================================================================
# Simple S3 Bucket Example
# =============================================================================
# Creates a basic S3 bucket with security defaults:
# - Encryption enabled (SSE-S3)
# - Versioning enabled
# - Public access blocked
# - TLS enforcement policy

terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# S3 Bucket Module
# -----------------------------------------------------------------------------

module "s3_buckets" {
  source = "../../s3"

  create       = true
  account_name = var.account_name
  project_name = var.project_name

  # Optional: Override auto-detected region prefix
  # region_prefix = "ause1"

  # Simple bucket with security defaults
  buckets = {
    data = {
      # Core settings
      force_destroy       = true # Set to false in production
      object_lock_enabled = false

      # Versioning (enabled by default)
      enable_versioning = true

      # Encryption (enabled by default)
      enable_encryption = true
      encryption_type   = "AES256" # SSE-S3

      # Public access block (enabled by default)
      enable_public_access_block = true

      # Bucket policy (TLS enforcement enabled by default)
      create_bucket_policy = true

      # Tags
      tags = {
        Environment = "dev"
        Purpose     = "example"
      }
    }
  }

  # Common tags applied to all buckets
  tags_common = {
    ManagedBy = "Terraform"
    Example   = "simple"
  }
}
