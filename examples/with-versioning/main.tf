# =============================================================================
# S3 Bucket with Advanced Versioning and Lifecycle Example
# =============================================================================
# Demonstrates:
# - Versioning with lifecycle rules
# - Multiple storage class transitions
# - Noncurrent version expiration
# - Abort incomplete multipart uploads
# - Advanced filtering (prefix, object size)

terraform {
  required_version = ">= 1.0"

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

  buckets = {
    # Data bucket with tiered storage lifecycle
    data = {
      force_destroy       = true
      object_lock_enabled = false

      # Versioning enabled
      enable_versioning     = true
      versioning_mfa_delete = false

      # Encryption
      enable_encryption = true
      encryption_type   = "AES256"

      # Lifecycle rules for cost optimization
      lifecycle_rules = {
        # Archive old data through multiple storage tiers
        archive_old_data = {
          enabled = true

          # Transitions for current versions
          transitions = [
            {
              days          = 30
              storage_class = "STANDARD_IA"
            },
            {
              days          = 90
              storage_class = "GLACIER_IR"
            },
            {
              days          = 180
              storage_class = "GLACIER"
            },
            {
              days          = 365
              storage_class = "DEEP_ARCHIVE"
            }
          ]

          # Expire old versions
          noncurrent_version_transitions = [
            {
              noncurrent_days = 30
              storage_class   = "STANDARD_IA"
            },
            {
              noncurrent_days = 90
              storage_class   = "GLACIER"
            }
          ]

          noncurrent_version_expiration_days = 180
          noncurrent_version_newer_versions  = 3

          # Clean up incomplete uploads
          abort_incomplete_multipart_upload_days = 7
        }

        # Expire temporary files quickly
        expire_temp_files = {
          enabled       = true
          filter_prefix = "temp/"

          expiration_days = 7

          # Also expire old versions quickly
          noncurrent_version_expiration_days = 1
        }

        # Archive logs with size filter
        archive_large_logs = {
          enabled                         = true
          filter_prefix                   = "logs/"
          filter_object_size_greater_than = 1048576 # 1 MB

          transitions = [
            {
              days          = 7
              storage_class = "GLACIER"
            }
          ]

          expiration_days = 90
        }
      }

      # Public access block
      enable_public_access_block = true

      # Bucket policy
      create_bucket_policy = true

      tags = {
        Environment = "production"
        DataType    = "archive"
      }
    }

    # Backup bucket with strict retention
    backups = {
      force_destroy       = true
      object_lock_enabled = false

      enable_versioning = true

      enable_encryption = true
      encryption_type   = "AES256"

      lifecycle_rules = {
        retain_backups = {
          enabled = true

          # Keep current backups for 1 year before archiving
          transitions = [
            {
              days          = 365
              storage_class = "GLACIER"
            }
          ]

          expiration_days = 2555 # 7 years

          # Keep 10 previous versions
          noncurrent_version_expiration_days = 90
          noncurrent_version_newer_versions  = 10

          abort_incomplete_multipart_upload_days = 3
        }
      }

      enable_public_access_block = true
      create_bucket_policy       = true

      tags = {
        Environment = "production"
        DataType    = "backups"
      }
    }
  }

  tags_common = {
    ManagedBy = "Terraform"
    Example   = "with-versioning"
  }
}
