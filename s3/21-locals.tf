# =============================================================================
# Local Values - Centralized Logic and Data Transformations
# =============================================================================
# This file contains all local values used for:
# - Region prefix auto-detection
# - Bucket naming logic
# - Conditional resource maps for for_each filtering
# - Combined tags

locals {
  # ---------------------------------------------------------------------------
  # Region Prefix Mapping
  # ---------------------------------------------------------------------------
  # Maps AWS region names to short prefixes for resource naming
  # Pattern: {continent}{region}{number}
  # Examples: us-east-1 → ause1, eu-west-1 → euw1

  region_prefix_map = {
    "us-east-1"      = "ause1"
    "us-east-2"      = "ause2"
    "us-west-1"      = "usw1"
    "us-west-2"      = "usw2"
    "af-south-1"     = "afs1"
    "ap-east-1"      = "ape1"
    "ap-south-1"     = "aps1"
    "ap-south-2"     = "aps2"
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-southeast-3" = "apse3"
    "ap-southeast-4" = "apse4"
    "ap-northeast-1" = "apne1"
    "ap-northeast-2" = "apne2"
    "ap-northeast-3" = "apne3"
    "ca-central-1"   = "cac1"
    "ca-west-1"      = "caw1"
    "eu-central-1"   = "euc1"
    "eu-central-2"   = "euc2"
    "eu-west-1"      = "euw1"
    "eu-west-2"      = "euw2"
    "eu-west-3"      = "euw3"
    "eu-south-1"     = "eus1"
    "eu-south-2"     = "eus2"
    "eu-north-1"     = "eun1"
    "il-central-1"   = "ilc1"
    "me-south-1"     = "mes1"
    "me-central-1"   = "mec1"
    "sa-east-1"      = "sae1"
  }

  # Auto-detect region prefix or use override
  region_prefix = var.region_prefix != null ? var.region_prefix : lookup(
    local.region_prefix_map,
    data.aws_region.current.id,
    "unknown"
  )

  # Name prefix: includes region prefix with trailing dash, or empty string
  name_prefix = var.use_region_prefix ? "${local.region_prefix}-" : ""

  # ---------------------------------------------------------------------------
  # Bucket Naming
  # ---------------------------------------------------------------------------
  # Generate bucket names using pattern:
  # {region_prefix}-s3-{account_name}-{project_name}-{key}
  # Example: ause1-s3-prod-myapp-data

  bucket_names = {
    for k, v in var.buckets :
    k => "${local.name_prefix}s3-${var.account_name}-${var.project_name}-${k}"
  }

  # ---------------------------------------------------------------------------
  # Conditional Bucket Maps (for for_each filtering)
  # ---------------------------------------------------------------------------
  # These maps filter buckets based on feature enablement
  # Used in resource definitions to conditionally create resources

  # Buckets with versioning enabled
  buckets_with_versioning = {
    for k, v in var.buckets :
    k => v if v.enable_versioning
  }

  # Buckets with encryption enabled
  buckets_with_encryption = {
    for k, v in var.buckets :
    k => v if v.enable_encryption
  }

  # Buckets with public access block enabled
  buckets_with_public_access_block = {
    for k, v in var.buckets :
    k => v if v.enable_public_access_block
  }

  # Buckets with website hosting enabled
  buckets_with_website = {
    for k, v in var.buckets :
    k => v if v.enable_website && v.website_config != null
  }

  # Buckets with CORS rules
  buckets_with_cors = {
    for k, v in var.buckets :
    k => v if length(v.cors_rules) > 0
  }

  # Buckets with logging enabled
  buckets_with_logging = {
    for k, v in var.buckets :
    k => v if v.enable_logging && v.logging_config != null
  }

  # Buckets with transfer acceleration enabled
  buckets_with_acceleration = {
    for k, v in var.buckets :
    k => v if v.enable_acceleration
  }

  # Buckets with replication enabled
  buckets_with_replication = {
    for k, v in var.buckets :
    k => v if v.enable_replication && v.replication_config != null
  }

  # Buckets with object lock enabled
  buckets_with_object_lock = {
    for k, v in var.buckets :
    k => v if v.object_lock_enabled
  }

  # Buckets with object lock configuration (retention rules)
  buckets_with_object_lock_config = {
    for k, v in var.buckets :
    k => v if v.object_lock_enabled && v.object_lock_config != null
  }

  # Buckets with ownership controls
  buckets_with_ownership_controls = {
    for k, v in var.buckets :
    k => v if v.object_ownership != null
  }

  # Buckets with ACL (only when ownership != BucketOwnerEnforced)
  buckets_with_acl = {
    for k, v in var.buckets :
    k => v if v.acl != null && v.object_ownership != "BucketOwnerEnforced"
  }

  # Buckets with request payment
  buckets_with_request_payment = {
    for k, v in var.buckets :
    k => v if v.request_payer != "BucketOwner"
  }

  # Buckets with notifications enabled
  buckets_with_notifications = {
    for k, v in var.buckets :
    k => v if v.notifications != null && (
      length(try(v.notifications.sns_topics, {})) > 0 ||
      length(try(v.notifications.sqs_queues, {})) > 0 ||
      length(try(v.notifications.lambda_functions, {})) > 0 ||
      try(v.notifications.enable_eventbridge, false)
    )
  }

  # Buckets requiring intelligent tiering configurations
  buckets_with_intelligent_tiering = {
    for k, v in var.buckets :
    k => v if length(v.intelligent_tiering_configs) > 0
  }

  # Buckets with inventory configurations
  buckets_with_inventory = {
    for k, v in var.buckets :
    k => v if length(v.inventory_configs) > 0
  }

  # Buckets with analytics configurations
  buckets_with_analytics = {
    for k, v in var.buckets :
    k => v if length(v.analytics_configs) > 0
  }

  # Buckets with metrics configurations
  buckets_with_metrics = {
    for k, v in var.buckets :
    k => v if length(v.metrics_configs) > 0
  }

  # ---------------------------------------------------------------------------
  # Bucket Policy Filters
  # ---------------------------------------------------------------------------
  # Filter buckets that need specific policy types

  # Buckets requiring bucket policy (any policy type)
  buckets_with_any_policy = {
    for k, v in var.buckets :
    k => v if(
      v.create_bucket_policy ||
      v.attach_elb_log_policy ||
      v.attach_lb_log_policy ||
      v.attach_cloudtrail_policy ||
      v.attach_waf_log_policy ||
      v.custom_policy_statements != null
    )
  }

  # Buckets with ELB/ALB/NLB log delivery policy
  buckets_with_elb_policy = {
    for k, v in var.buckets :
    k => v if v.attach_elb_log_policy || v.attach_lb_log_policy
  }

  # Buckets with CloudTrail log delivery policy
  buckets_with_cloudtrail_policy = {
    for k, v in var.buckets :
    k => v if v.attach_cloudtrail_policy
  }

  # Buckets with WAF log delivery policy
  buckets_with_waf_policy = {
    for k, v in var.buckets :
    k => v if v.attach_waf_log_policy
  }

  # ---------------------------------------------------------------------------
  # Flattened Configuration Maps
  # ---------------------------------------------------------------------------
  # These maps flatten nested bucket.config_map structures for resources
  # that need unique IDs across all buckets

  # Flatten intelligent tiering configurations
  flattened_intelligent_tiering_configs = merge([
    for bucket_key, bucket in var.buckets : {
      for config_key, config in bucket.intelligent_tiering_configs :
      "${bucket_key}-${config_key}" => merge(config, {
        bucket_key = bucket_key
      })
    } if length(bucket.intelligent_tiering_configs) > 0
  ]...)

  # Flatten inventory configurations
  flattened_inventory_configs = merge([
    for bucket_key, bucket in var.buckets : {
      for config_key, config in bucket.inventory_configs :
      "${bucket_key}-${config_key}" => merge(config, {
        bucket_key                  = bucket_key
        destination_bucket_arn      = config.destination_bucket
        destination_encryption_type = config.destination_encryption_type == "SSE-S3" ? "sse_s3" : config.destination_encryption_type == "SSE-KMS" ? "sse_kms" : null
      })
    } if length(bucket.inventory_configs) > 0
  ]...)

  # Flatten analytics configurations
  flattened_analytics_configs = merge([
    for bucket_key, bucket in var.buckets : {
      for config_key, config in bucket.analytics_configs :
      "${bucket_key}-${config_key}" => merge(config, {
        bucket_key                    = bucket_key
        export_destination_bucket_arn = config.storage_class_analysis_data_export_destination_bucket
        export_destination_prefix     = config.storage_class_analysis_data_export_destination_prefix
        export_encryption_type        = null # Not supported in analytics export
        export_kms_key_id             = null # Not supported in analytics export
      })
    } if length(bucket.analytics_configs) > 0
  ]...)

  # Flatten metrics configurations
  flattened_metrics_configs = merge([
    for bucket_key, bucket in var.buckets : {
      for config_key, config in bucket.metrics_configs :
      "${bucket_key}-${config_key}" => merge(config, {
        bucket_key              = bucket_key
        filter_access_point_arn = null # Add if needed in future
      })
    } if length(bucket.metrics_configs) > 0
  ]...)

  # ---------------------------------------------------------------------------
  # Combined Tags
  # ---------------------------------------------------------------------------
  # Merge common tags with bucket-specific tags
  # Adds default tags for Name, BucketKey, AccountName, ProjectName

  bucket_tags = {
    for k, v in var.buckets :
    k => merge(
      var.tags_common,
      {
        Name        = local.bucket_names[k]
        BucketKey   = k
        AccountName = var.account_name
        ProjectName = var.project_name
      },
      v.tags
    )
  }

  # ---------------------------------------------------------------------------
  # Custom Policy Placeholders Replacement
  # ---------------------------------------------------------------------------
  # Replaces placeholders in custom policy statements with actual bucket values
  # Supported placeholders:
  #   {{BUCKET_ID}}   - Bucket name/ID (e.g., "ause1-s3-prod-myapp-data")
  #   {{BUCKET_ARN}}  - Bucket ARN (e.g., "arn:aws:s3:::ause1-s3-prod-myapp-data")
  #   {{ACCOUNT_ID}}  - AWS Account ID (e.g., "123456789012")
  #   {{REGION}}      - AWS Region (e.g., "us-east-1")
  #
  # Usage example:
  #   custom_policy_statements = jsonencode({
  #     Resource = ["{{BUCKET_ARN}}", "{{BUCKET_ARN}}/*"]
  #   })
  #
  # This allows users to write policies without calculating bucket names

  custom_policies_with_placeholders = {
    for k, v in var.buckets :
    k => v.custom_policy_statements != null ? replace(
      replace(
        replace(
          replace(
            v.custom_policy_statements,
            "{{BUCKET_ID}}", local.bucket_names[k]
          ),
          "{{BUCKET_ARN}}", "arn:aws:s3:::${local.bucket_names[k]}"
        ),
        "{{ACCOUNT_ID}}", data.aws_caller_identity.current.account_id
      ),
      "{{REGION}}", data.aws_region.current.id
    ) : null
  }
}
