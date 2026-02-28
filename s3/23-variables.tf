# =============================================================================
# Input Variables
# =============================================================================
# This file defines all input variables for the S3 module
# Supports 22+ S3 features with security-conscious defaults

# =============================================================================
# Main Buckets Configuration
# =============================================================================

variable "buckets" {
  description = "Map of S3 bucket configurations with comprehensive features"
  type = map(object({

    # -------------------------------------------------------------------------
    # Basic Configuration
    # -------------------------------------------------------------------------
    force_destroy       = optional(bool, false) # Allow deletion with objects
    object_lock_enabled = optional(bool, false) # Enable object locking

    # -------------------------------------------------------------------------
    # Versioning
    # -------------------------------------------------------------------------
    enable_versioning     = optional(bool, true)  # Enable versioning (default: true for data protection)
    versioning_mfa_delete = optional(bool, false) # Require MFA for version deletion

    # -------------------------------------------------------------------------
    # Server-Side Encryption
    # -------------------------------------------------------------------------
    enable_encryption  = optional(bool, true)       # Enable encryption (default: true for security)
    encryption_type    = optional(string, "AES256") # "AES256" (SSE-S3) or "aws:kms" (SSE-KMS)
    kms_key_id         = optional(string, null)     # KMS key ID/ARN (required if encryption_type = "aws:kms")
    bucket_key_enabled = optional(bool, true)       # Use S3 Bucket Keys (reduces KMS costs)

    # -------------------------------------------------------------------------
    # Advanced Lifecycle Rules
    # -------------------------------------------------------------------------
    lifecycle_rules = optional(map(object({
      enabled = optional(bool, true)

      # Filters
      filter_prefix                   = optional(string, null)
      filter_tags                     = optional(map(string), null)
      filter_object_size_greater_than = optional(number, null)
      filter_object_size_less_than    = optional(number, null)

      # Current version transitions
      transitions = optional(list(object({
        days          = optional(number, null)
        date          = optional(string, null)
        storage_class = string # STANDARD_IA, INTELLIGENT_TIERING, ONEZONE_IA, GLACIER_IR, GLACIER, DEEP_ARCHIVE
      })), [])

      # Noncurrent version transitions
      noncurrent_version_transitions = optional(list(object({
        noncurrent_days = number
        storage_class   = string
      })), [])

      # Expiration
      expiration_days                         = optional(number, null)
      expiration_date                         = optional(string, null)
      expiration_expired_object_delete_marker = optional(bool, false)

      # Noncurrent version expiration
      noncurrent_version_expiration_days = optional(number, null)
      noncurrent_version_newer_versions  = optional(number, null) # Keep N newest versions

      # Abort incomplete multipart uploads
      abort_incomplete_multipart_upload_days = optional(number, null)
    })), {})

    # -------------------------------------------------------------------------
    # Static Website Hosting
    # -------------------------------------------------------------------------
    enable_website = optional(bool, false)
    website_config = optional(object({
      index_document = optional(string, "index.html")
      error_document = optional(string, "error.html")
      redirect_all_requests_to = optional(object({
        host_name = string
        protocol  = optional(string, "https")
      }), null)
      routing_rules = optional(string, null) # JSON string
    }), null)

    # -------------------------------------------------------------------------
    # CORS Configuration
    # -------------------------------------------------------------------------
    cors_rules = optional(list(object({
      allowed_headers = optional(list(string), [])
      allowed_methods = list(string) # GET, PUT, POST, DELETE, HEAD
      allowed_origins = list(string) # ["https://example.com", "*"]
      expose_headers  = optional(list(string), [])
      max_age_seconds = optional(number, 3000)
    })), [])

    # -------------------------------------------------------------------------
    # Access Logging
    # -------------------------------------------------------------------------
    enable_logging = optional(bool, false)
    logging_config = optional(object({
      target_bucket = string               # Bucket to store access logs
      target_prefix = optional(string, "") # Prefix for log objects
    }), null)

    # -------------------------------------------------------------------------
    # Transfer Acceleration
    # -------------------------------------------------------------------------
    enable_acceleration = optional(bool, false) # Enable S3 Transfer Acceleration

    # -------------------------------------------------------------------------
    # Cross-Region/Same-Region Replication
    # -------------------------------------------------------------------------
    enable_replication = optional(bool, false)
    replication_config = optional(object({
      role_arn = string # IAM role ARN for replication

      rules = map(object({
        enabled  = optional(bool, true)
        priority = optional(number, 0)

        # Filter
        filter_prefix = optional(string, null)
        filter_tags   = optional(map(string), null)

        # Destination
        destination_bucket             = string                       # ARN of destination bucket
        destination_storage_class      = optional(string, "STANDARD") # Storage class in destination
        destination_account_id         = optional(string, null)       # Cross-account replication
        destination_replica_kms_key_id = optional(string, null)       # KMS key for replica encryption
        destination_access_control_translation = optional(object({
          owner = string # Destination (change ownership to destination account)
        }), null)

        # Options
        delete_marker_replication_enabled                   = optional(bool, false)
        source_selection_criteria_sse_kms_encrypted_objects = optional(bool, false)

        # Replication Time Control
        replication_time_control_enabled = optional(bool, false)
        replication_time_minutes         = optional(number, 15)

        # Metrics
        metrics_enabled = optional(bool, false)
        metrics_minutes = optional(number, 15)
      }))
    }), null)

    # -------------------------------------------------------------------------
    # Object Lock Configuration
    # -------------------------------------------------------------------------
    object_lock_config = optional(object({
      rule_default_retention_mode  = optional(string, null) # GOVERNANCE or COMPLIANCE
      rule_default_retention_days  = optional(number, null)
      rule_default_retention_years = optional(number, null)
    }), null)

    # -------------------------------------------------------------------------
    # Intelligent Tiering
    # -------------------------------------------------------------------------
    intelligent_tiering_configs = optional(map(object({
      status = optional(string, "Enabled") # Enabled or Disabled

      # Filter
      filter_prefix = optional(string, null)
      filter_tags   = optional(map(string), null)

      # Tiering configurations
      tierings = list(object({
        access_tier = string # ARCHIVE_ACCESS or DEEP_ARCHIVE_ACCESS
        days        = number # Days after last access
      }))
    })), {})

    # -------------------------------------------------------------------------
    # S3 Inventory
    # -------------------------------------------------------------------------
    inventory_configs = optional(map(object({
      enabled                  = optional(bool, true)
      included_object_versions = optional(string, "All") # All or Current

      # Schedule
      frequency = string # Daily or Weekly

      # Destination
      destination_bucket          = string                  # ARN of destination bucket
      destination_prefix          = optional(string, "")    # Prefix for inventory reports
      destination_format          = optional(string, "ORC") # ORC, Parquet, CSV
      destination_account_id      = optional(string, null)
      destination_encryption_type = optional(string, null) # SSE-S3 or SSE-KMS
      destination_kms_key_id      = optional(string, null)

      # Optional fields to include in report
      optional_fields = optional(list(string), []) # Size, LastModifiedDate, StorageClass, etc.

      # Filter
      filter_prefix = optional(string, null)
    })), {})

    # -------------------------------------------------------------------------
    # S3 Analytics
    # -------------------------------------------------------------------------
    analytics_configs = optional(map(object({
      # Filter
      filter_prefix = optional(string, null)
      filter_tags   = optional(map(string), null)

      # Storage class analysis
      storage_class_analysis_data_export_enabled            = optional(bool, true)
      storage_class_analysis_data_export_destination_bucket = optional(string, null) # ARN of destination
      storage_class_analysis_data_export_destination_prefix = optional(string, null)
    })), {})

    # -------------------------------------------------------------------------
    # Request Metrics
    # -------------------------------------------------------------------------
    metrics_configs = optional(map(object({
      # Filter
      filter_prefix = optional(string, null)
      filter_tags   = optional(map(string), null)
    })), {})

    # -------------------------------------------------------------------------
    # Event Notifications
    # -------------------------------------------------------------------------
    notifications = optional(object({
      # SNS Topic notifications
      sns_topics = optional(map(object({
        topic_arn     = string
        events        = list(string) # s3:ObjectCreated:*, s3:ObjectRemoved:*, etc.
        filter_prefix = optional(string, null)
        filter_suffix = optional(string, null)
      })), {})

      # SQS Queue notifications
      sqs_queues = optional(map(object({
        queue_arn     = string
        events        = list(string)
        filter_prefix = optional(string, null)
        filter_suffix = optional(string, null)
      })), {})

      # Lambda Function notifications
      lambda_functions = optional(map(object({
        function_arn  = string
        events        = list(string)
        filter_prefix = optional(string, null)
        filter_suffix = optional(string, null)
      })), {})

      # EventBridge
      enable_eventbridge = optional(bool, false)
    }), null)

    # -------------------------------------------------------------------------
    # Object Ownership Controls
    # -------------------------------------------------------------------------
    object_ownership = optional(string, "BucketOwnerEnforced") # BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced

    # -------------------------------------------------------------------------
    # Access Control List (ACL)
    # -------------------------------------------------------------------------
    acl = optional(string, null) # private, public-read, public-read-write, etc.
    # Note: ACL conflicts with object_ownership = "BucketOwnerEnforced"

    # -------------------------------------------------------------------------
    # Request Payment
    # -------------------------------------------------------------------------
    request_payer = optional(string, "BucketOwner") # BucketOwner or Requester

    # -------------------------------------------------------------------------
    # Bucket Policy
    # -------------------------------------------------------------------------
    create_bucket_policy     = optional(bool, true)   # Create default TLS-enforcing policy
    attach_elb_log_policy    = optional(bool, false)  # Allow ELB log delivery
    attach_lb_log_policy     = optional(bool, false)  # Alias for attach_elb_log_policy
    attach_cloudtrail_policy = optional(bool, false)  # Allow CloudTrail log delivery
    attach_waf_log_policy    = optional(bool, false)  # Allow WAF log delivery
    custom_policy_statements = optional(string, null) # Custom policy JSON

    # -------------------------------------------------------------------------
    # Public Access Block
    # -------------------------------------------------------------------------
    enable_public_access_block = optional(bool, true)
    public_access_block_config = optional(object({
      block_public_acls       = optional(bool, true)
      block_public_policy     = optional(bool, true)
      ignore_public_acls      = optional(bool, true)
      restrict_public_buckets = optional(bool, true)
    }), null)

    # -------------------------------------------------------------------------
    # Tags
    # -------------------------------------------------------------------------
    tags = optional(map(string), {}) # Bucket-specific tags

  }))

  # ===========================================================================
  # Validation Rules
  # ===========================================================================

  # Validation: KMS encryption requires kms_key_id
  validation {
    condition = alltrue([
      for k, v in var.buckets :
      v.encryption_type == "aws:kms" ? v.kms_key_id != null : true
    ])
    error_message = "When encryption_type is 'aws:kms', kms_key_id must be provided."
  }

  # Validation: Replication requires versioning
  validation {
    condition = alltrue([
      for k, v in var.buckets :
      v.enable_replication ? v.enable_versioning : true
    ])
    error_message = "Replication requires versioning to be enabled."
  }

  # Validation: Object ownership values
  validation {
    condition = alltrue([
      for k, v in var.buckets :
      contains(["BucketOwnerPreferred", "ObjectWriter", "BucketOwnerEnforced"], v.object_ownership)
    ])
    error_message = "object_ownership must be one of: BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced."
  }

  # Validation: ACL conflicts with BucketOwnerEnforced
  validation {
    condition = alltrue([
      for k, v in var.buckets :
      v.object_ownership == "BucketOwnerEnforced" ? v.acl == null : true
    ])
    error_message = "ACL cannot be used when object_ownership is 'BucketOwnerEnforced'."
  }

  # Validation: Website config required when website enabled
  validation {
    condition = alltrue([
      for k, v in var.buckets :
      v.enable_website ? v.website_config != null : true
    ])
    error_message = "website_config must be provided when enable_website is true."
  }

  # Validation: Logging config required when logging enabled
  validation {
    condition = alltrue([
      for k, v in var.buckets :
      v.enable_logging ? v.logging_config != null : true
    ])
    error_message = "logging_config must be provided when enable_logging is true."
  }

  # Validation: Replication config required when replication enabled
  validation {
    condition = alltrue([
      for k, v in var.buckets :
      v.enable_replication ? v.replication_config != null : true
    ])
    error_message = "replication_config must be provided when enable_replication is true."
  }

  # Validation: Object lock config required when object lock enabled
  validation {
    condition = alltrue([
      for k, v in var.buckets :
      v.object_lock_enabled ? v.object_lock_config != null : true
    ])
    error_message = "object_lock_config must be provided when object_lock_enabled is true."
  }

  # Validation: Encryption type must be valid
  validation {
    condition = alltrue([
      for k, v in var.buckets :
      contains(["AES256", "aws:kms"], v.encryption_type)
    ])
    error_message = "encryption_type must be either 'AES256' or 'aws:kms'."
  }
}

# =============================================================================
# Supporting Variables
# =============================================================================

variable "account_name" {
  description = "Account name for resource naming (e.g., 'prod', 'dev', 'staging')"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming (e.g., 'myapp', 'website')"
  type        = string
}

variable "region_prefix" {
  description = "Region prefix for bucket naming. If not provided, auto-derived from current AWS region. Examples: 'ause1' (us-east-1), 'euw1' (eu-west-1)"
  type        = string
  default     = null
}

variable "use_region_prefix" {
  description = "Whether to include the region prefix in resource names. When false, names omit the region prefix."
  type        = bool
  default     = true
}

variable "tags_common" {
  description = "Common tags to apply to all S3 buckets in addition to bucket-specific tags"
  type        = map(string)
  default     = {}
}

variable "create" {
  description = "Master toggle to enable/disable creation of all resources"
  type        = bool
  default     = true
}
