# =============================================================================
# S3 Cross-Region Replication Example
# =============================================================================
# Demonstrates cross-region replication for disaster recovery and compliance

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "replica"
  region = var.replica_region
}

# -----------------------------------------------------------------------------
# IAM Role for Replication
# -----------------------------------------------------------------------------

resource "aws_iam_role" "replication" {
  provider = aws.primary
  name     = "${var.account_name}-${var.project_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "replication" {
  provider = aws.primary
  role     = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          module.primary_bucket.bucket_arns["source"]
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "${module.primary_bucket.bucket_arns["source"]}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          "${module.replica_bucket.bucket_arns["destination"]}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Primary Bucket (Source)
# -----------------------------------------------------------------------------

module "primary_bucket" {
  source = "../../s3"

  providers = {
    aws = aws.primary
  }

  create        = true
  account_name  = var.account_name
  project_name  = var.project_name
  region_prefix = var.primary_region_prefix

  buckets = {
    source = {
      force_destroy       = true
      object_lock_enabled = false

      # Versioning required for replication
      enable_versioning = true

      # Encryption
      enable_encryption = true
      encryption_type   = "AES256"

      # Replication configuration
      # The module selects the replication schema per rule:
      #   - Schema V1: rule without filter and without delete marker replication
      #   - Schema V2: rule with filter_prefix/filter_tags or
      #     delete_marker_replication_enabled = true (priority and
      #     delete_marker_replication are then sent automatically)
      enable_replication = true
      replication_config = {
        role_arn = aws_iam_role.replication.arn

        rules = {
          replicate_all = {
            enabled = true

            destination_bucket        = module.replica_bucket.bucket_arns["destination"]
            destination_storage_class = "STANDARD"

            delete_marker_replication_enabled = false
            metrics_enabled                   = false
            replication_time_control_enabled  = false
          }

          # Multiple rules require schema V2: give every rule a filter and a
          # unique priority (and a filter on the first rule as well)
          # replicate_docs = {
          #   enabled       = true
          #   priority      = 2
          #   filter_prefix = "documents/"
          #
          #   destination_bucket        = module.replica_bucket.bucket_arns["destination"]
          #   destination_storage_class = "GLACIER"
          #
          #   delete_marker_replication_enabled = false
          #   metrics_enabled                   = false
          #   replication_time_control_enabled  = false
          # }
        }
      }

      enable_public_access_block = true
      create_bucket_policy       = true

      tags = {
        Environment = "production"
        Type        = "primary"
      }
    }
  }

  tags_common = {
    ManagedBy = "Terraform"
    Example   = "with-replication"
  }
}

# -----------------------------------------------------------------------------
# Replica Bucket (Destination)
# -----------------------------------------------------------------------------

module "replica_bucket" {
  source = "../../s3"

  providers = {
    aws = aws.replica
  }

  create        = true
  account_name  = var.account_name
  project_name  = var.project_name
  region_prefix = var.replica_region_prefix

  buckets = {
    destination = {
      force_destroy       = true
      object_lock_enabled = false

      # Versioning required for replication
      enable_versioning = true

      # Encryption
      enable_encryption = true
      encryption_type   = "AES256"

      enable_public_access_block = true
      create_bucket_policy       = true

      tags = {
        Environment = "production"
        Type        = "replica"
      }
    }
  }

  tags_common = {
    ManagedBy = "Terraform"
    Example   = "with-replication"
  }
}
