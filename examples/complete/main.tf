# =============================================================================
# Complete S3 Module Example - All Features
# =============================================================================
# Reference implementation demonstrating ALL available S3 features

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

module "s3_buckets" {
  source = "../../s3"

  create       = true
  account_name = var.account_name
  project_name = var.project_name

  buckets = {
    # ==========================================================================
    # Complete Feature Demonstration Bucket
    # ==========================================================================
    complete = {
      force_destroy       = true
      object_lock_enabled = false

      # Versioning
      enable_versioning     = true
      versioning_mfa_delete = false

      # Encryption
      enable_encryption  = true
      encryption_type    = "AES256"
      bucket_key_enabled = true

      # Advanced Lifecycle Rules
      lifecycle_rules = {
        tiered_storage = {
          enabled = true

          transitions = [
            { days = 30, storage_class = "STANDARD_IA" },
            { days = 90, storage_class = "GLACIER_IR" },
            { days = 180, storage_class = "GLACIER" },
            { days = 365, storage_class = "DEEP_ARCHIVE" }
          ]

          noncurrent_version_transitions = [
            { noncurrent_days = 30, storage_class = "STANDARD_IA" },
            { noncurrent_days = 90, storage_class = "GLACIER" }
          ]

          expiration_days                    = 2555 # 7 years
          noncurrent_version_expiration_days = 90
          noncurrent_version_newer_versions  = 5

          abort_incomplete_multipart_upload_days = 7
        }

        temp_cleanup = {
          enabled         = true
          filter_prefix   = "temp/"
          expiration_days = 1
        }

        large_files = {
          enabled                         = true
          filter_object_size_greater_than = 10485760 # 10 MB

          transitions = [
            { days = 7, storage_class = "GLACIER" }
          ]
        }
      }

      # Public Access Block
      enable_public_access_block = true
      public_access_block_config = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }

      # Bucket Policy with Placeholders
      create_bucket_policy     = true
      attach_elb_log_policy    = false
      attach_cloudtrail_policy = false
      attach_waf_log_policy    = false

      # Custom policy using placeholders (automatically replaced)
      custom_policy_statements = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "AllowCrossAccountRead"
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::{{ACCOUNT_ID}}:root"
            }
            Action = [
              "s3:GetObject",
              "s3:ListBucket"
            ]
            Resource = [
              "{{BUCKET_ARN}}",
              "{{BUCKET_ARN}}/*"
            ]
          }
        ]
      })

      # Transfer Acceleration
      enable_acceleration = true

      # Logging
      enable_logging = false # Set to true with target bucket

      # Intelligent Tiering
      intelligent_tiering_configs = {
        archive_config = {
          status        = "Enabled"
          filter_prefix = "archive/"

          tierings = [
            { access_tier = "ARCHIVE_ACCESS", days = 90 },
            { access_tier = "DEEP_ARCHIVE_ACCESS", days = 180 }
          ]
        }
      }

      # Inventory
      inventory_configs = {
        weekly_inventory = {
          enabled                  = true
          included_object_versions = "All"
          frequency                = "Weekly"
          destination_bucket       = "arn:aws:s3:::inventory-bucket"
          destination_prefix       = "inventory/"
          destination_format       = "ORC"
          optional_fields = [
            "Size",
            "LastModifiedDate",
            "StorageClass",
            "ETag",
            "IsMultipartUploaded",
            "ReplicationStatus",
            "EncryptionStatus"
          ]
        }
      }

      # Analytics
      analytics_configs = {
        storage_analysis = {
          storage_class_analysis_data_export_enabled            = true
          storage_class_analysis_data_export_destination_bucket = "arn:aws:s3:::analytics-bucket"
          storage_class_analysis_data_export_destination_prefix = "analytics/"
        }
      }

      # Request Metrics
      metrics_configs = {
        all_objects = {
          # Metrics for all objects
        }

        documents = {
          filter_prefix = "documents/"
        }
      }

      # Event Notifications
      # IMPORTANT: Each notification rule must have non-overlapping filters
      # to avoid "Configuration is ambiguously defined" errors
      notifications = {
        enable_eventbridge = true

        lambda_functions = {
          process_uploads = {
            function_arn  = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:process-s3-upload"
            events        = ["s3:ObjectCreated:*"]
            filter_prefix = "uploads/"
            filter_suffix = ".jpg"
          }
        }

        sns_topics = {
          deletion_alerts = {
            topic_arn     = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:s3-deletions"
            events        = ["s3:ObjectRemoved:*"]
            filter_prefix = "archived/" # Must have non-overlapping prefix to avoid conflicts
          }
        }
      }

      # Object Ownership
      object_ownership = "BucketOwnerEnforced"

      # Request Payment
      request_payer = "BucketOwner"

      tags = {
        Environment = "production"
        Complete    = "true"
        Features    = "all"
      }
    }

    # ==========================================================================
    # Object Lock Bucket
    # ==========================================================================
    compliance = {
      force_destroy       = true
      object_lock_enabled = true

      enable_versioning = true

      enable_encryption = true
      encryption_type   = "AES256"

      # Object Lock Configuration
      object_lock_config = {
        rule_default_retention_mode = "COMPLIANCE"
        rule_default_retention_days = 30
      }

      enable_public_access_block = true
      create_bucket_policy       = true

      object_ownership = "BucketOwnerEnforced"

      tags = {
        Environment = "production"
        Compliance  = "true"
        Retention   = "30-days"
      }
    }
  }

  tags_common = {
    ManagedBy = "Terraform"
    Example   = "complete"
  }
}

data "aws_caller_identity" "current" {}
