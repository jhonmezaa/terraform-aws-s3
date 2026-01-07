# =============================================================================
# S3 Log Delivery Buckets Example
# =============================================================================
# Demonstrates buckets configured for receiving logs from AWS services:
# - ELB/ALB/NLB access logs
# - CloudTrail audit logs
# - WAF logs

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
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
    # ELB/ALB/NLB Access Logs
    elb-logs = {
      force_destroy       = true
      object_lock_enabled = false

      enable_versioning = false
      enable_encryption = true
      encryption_type   = "AES256"

      # Attach ELB log delivery policy
      create_bucket_policy  = true
      attach_elb_log_policy = true

      # Lifecycle: expire old logs after 90 days
      lifecycle_rules = {
        expire_logs = {
          enabled         = true
          expiration_days = 90

          transitions = [
            {
              days          = 30
              storage_class = "STANDARD_IA"
            }
          ]

          abort_incomplete_multipart_upload_days = 7
        }
      }

      # Object ownership for log delivery
      object_ownership = "BucketOwnerPreferred"

      enable_public_access_block = true

      tags = {
        LogType = "elb"
      }
    }

    # CloudTrail Logs
    cloudtrail-logs = {
      force_destroy       = true
      object_lock_enabled = false

      enable_versioning = true # Recommended for audit logs
      enable_encryption = true
      encryption_type   = "AES256"

      # Attach CloudTrail log delivery policy
      create_bucket_policy     = true
      attach_cloudtrail_policy = true

      # Lifecycle: keep for compliance (7 years)
      lifecycle_rules = {
        retain_audit_logs = {
          enabled = true

          transitions = [
            {
              days          = 90
              storage_class = "STANDARD_IA"
            },
            {
              days          = 365
              storage_class = "GLACIER"
            }
          ]

          expiration_days = 2555 # 7 years

          # Keep all noncurrent versions for 30 days
          noncurrent_version_expiration_days = 30

          abort_incomplete_multipart_upload_days = 3
        }
      }

      object_ownership = "BucketOwnerPreferred"

      enable_public_access_block = true

      tags = {
        LogType    = "cloudtrail"
        Compliance = "true"
      }
    }

    # WAF Logs
    waf-logs = {
      force_destroy       = true
      object_lock_enabled = false

      enable_versioning = false
      enable_encryption = true
      encryption_type   = "AES256"

      # Attach WAF log delivery policy
      create_bucket_policy  = true
      attach_waf_log_policy = true

      # Lifecycle: expire after 30 days (security analysis window)
      lifecycle_rules = {
        expire_waf_logs = {
          enabled         = true
          expiration_days = 30

          abort_incomplete_multipart_upload_days = 1
        }
      }

      object_ownership = "BucketOwnerPreferred"

      enable_public_access_block = true

      tags = {
        LogType = "waf"
      }
    }

    # Centralized Application Logs with Custom Policy (Placeholder Demo)
    app-logs = {
      force_destroy       = true
      object_lock_enabled = false

      enable_versioning = false
      enable_encryption = true
      encryption_type   = "AES256"

      # TLS policy + Custom policy using placeholders
      create_bucket_policy = true

      # Custom policy example using placeholders
      # Placeholders are automatically replaced:
      #   {{BUCKET_ID}}   -> actual bucket name
      #   {{BUCKET_ARN}}  -> arn:aws:s3:::bucket-name
      #   {{ACCOUNT_ID}}  -> AWS account ID
      #   {{REGION}}      -> AWS region
      custom_policy_statements = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "AllowCrossAccountLogDelivery"
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::{{ACCOUNT_ID}}:root"
            }
            Action = [
              "s3:PutObject",
              "s3:PutObjectAcl"
            ]
            Resource = [
              "{{BUCKET_ARN}}/logs/*"
            ]
            Condition = {
              StringEquals = {
                "s3:x-amz-acl" = "bucket-owner-full-control"
              }
            }
          },
          {
            Sid    = "AllowReadLogsFromAccount"
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

      # Lifecycle: archive and expire
      lifecycle_rules = {
        archive_app_logs = {
          enabled = true

          transitions = [
            {
              days          = 7
              storage_class = "STANDARD_IA"
            },
            {
              days          = 30
              storage_class = "GLACIER"
            }
          ]

          expiration_days = 365

          abort_incomplete_multipart_upload_days = 1
        }
      }

      # Notifications for ERROR logs (commented - requires Lambda function to exist)
      # notifications = {
      #   lambda_functions = {
      #     error_alerts = {
      #       function_arn  = "arn:aws:lambda:{{REGION}}:{{ACCOUNT_ID}}:function:log-error-handler"
      #       events        = ["s3:ObjectCreated:*"]
      #       filter_prefix = "error/"
      #       filter_suffix = ".log"
      #     }
      #   }
      # }

      object_ownership = "BucketOwnerEnforced"

      enable_public_access_block = true

      tags = {
        LogType      = "application"
        CustomPolicy = "placeholder-example"
      }
    }
  }

  tags_common = {
    ManagedBy = "Terraform"
    Example   = "log-delivery"
    Purpose   = "logging"
  }
}

data "aws_caller_identity" "current" {}
