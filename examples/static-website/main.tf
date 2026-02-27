# =============================================================================
# S3 Static Website Example
# =============================================================================
# Demonstrates:
# - Static website hosting
# - CORS configuration for web applications
# - Public read access via bucket policy
# - Custom error pages

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

  buckets = {
    # Main website bucket
    website = {
      force_destroy       = true
      object_lock_enabled = false

      # Versioning for rollback capability
      enable_versioning = true

      # Encryption
      enable_encryption = true
      encryption_type   = "AES256"

      # Website hosting configuration
      enable_website = true
      website_config = {
        index_document = "index.html"
        error_document = "error.html"

        # Optional: redirect all requests to another domain
        # redirect_all_requests_to = {
        #   host_name = "example.com"
        #   protocol  = "https"
        # }

        # Optional: advanced routing rules (JSON)
        # routing_rules = jsonencode([{
        #   Condition = {
        #     KeyPrefixEquals = "docs/"
        #   }
        #   Redirect = {
        #     ReplaceKeyPrefixWith = "documentation/"
        #   }
        # }])
      }

      # CORS configuration for web apps
      cors_rules = [
        {
          allowed_origins = ["https://${var.domain_name}", "http://localhost:3000"]
          allowed_methods = ["GET", "HEAD"]
          allowed_headers = ["*"]
          expose_headers  = ["ETag"]
          max_age_seconds = 3000
        },
        {
          # Allow uploads from authenticated users
          allowed_origins = ["https://${var.domain_name}"]
          allowed_methods = ["PUT", "POST", "DELETE"]
          allowed_headers = ["*"]
          max_age_seconds = 3000
        }
      ]

      # Public access configuration
      # Note: For website hosting, we need to allow public reads
      enable_public_access_block = true
      public_access_block_config = {
        block_public_acls       = true
        block_public_policy     = false # Allow bucket policy for public reads
        ignore_public_acls      = true
        restrict_public_buckets = false # Allow public access via policy
      }

      # Bucket policy with public read access
      create_bucket_policy     = true
      custom_policy_statements = data.aws_iam_policy_document.website_policy.json

      # Object ownership (required for public access)
      object_ownership = "BucketOwnerPreferred"

      tags = {
        Environment = "production"
        Website     = "true"
      }
    }

    # Logs bucket for website access logs
    website-logs = {
      force_destroy       = true
      object_lock_enabled = false

      enable_versioning = false
      enable_encryption = true
      encryption_type   = "AES256"

      # Lifecycle rule to expire old logs
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
        }
      }

      # Object ownership for log delivery
      object_ownership = "BucketOwnerPreferred"

      # ACL for S3 log delivery
      acl = "log-delivery-write"

      # Full public access block for logs
      enable_public_access_block = true

      tags = {
        Environment = "production"
        Purpose     = "logs"
      }
    }
  }

  tags_common = {
    ManagedBy = "Terraform"
    Example   = "static-website"
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

# Custom policy for public website access
data "aws_iam_policy_document" "website_policy" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_names["website"]}/*",
    ]
  }
}

# Calculate bucket names for policy
locals {
  region_prefix_map = {
    "us-east-1" = "ause1"
    "us-west-2" = "usw2"
    "eu-west-1" = "euw1"
  }

  region_prefix = lookup(local.region_prefix_map, var.aws_region, "ause1")

  bucket_names = {
    "website" = "${local.region_prefix}-s3-${var.account_name}-${var.project_name}-website"
  }
}

# -----------------------------------------------------------------------------
# Configure website logging
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_logging" "website_logs" {
  bucket = module.s3_buckets.bucket_ids["website"]

  target_bucket = module.s3_buckets.bucket_ids["website-logs"]
  target_prefix = "access-logs/"
}
