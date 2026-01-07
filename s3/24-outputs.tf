# =============================================================================
# S3 Module Outputs
# =============================================================================
# Comprehensive outputs exposing all bucket attributes and configurations

# -----------------------------------------------------------------------------
# Basic Bucket Outputs
# -----------------------------------------------------------------------------

output "bucket_ids" {
  description = "Map of bucket keys to bucket IDs (names)"
  value       = { for k, v in aws_s3_bucket.this : k => v.id }
}

output "bucket_arns" {
  description = "Map of bucket keys to bucket ARNs"
  value       = { for k, v in aws_s3_bucket.this : k => v.arn }
}

output "bucket_domain_names" {
  description = "Map of bucket keys to bucket domain names (FQDN)"
  value       = { for k, v in aws_s3_bucket.this : k => v.bucket_domain_name }
}

output "bucket_regional_domain_names" {
  description = "Map of bucket keys to bucket regional domain names"
  value       = { for k, v in aws_s3_bucket.this : k => v.bucket_regional_domain_name }
}

output "bucket_hosted_zone_ids" {
  description = "Map of bucket keys to Route 53 Hosted Zone IDs"
  value       = { for k, v in aws_s3_bucket.this : k => v.hosted_zone_id }
}

output "bucket_regions" {
  description = "Map of bucket keys to AWS regions"
  value       = { for k, v in aws_s3_bucket.this : k => v.region }
}

# -----------------------------------------------------------------------------
# Website Outputs
# -----------------------------------------------------------------------------

output "website_endpoints" {
  description = "Map of bucket keys to website endpoints (for buckets with website hosting enabled)"
  value = {
    for k, v in aws_s3_bucket_website_configuration.this :
    k => v.website_endpoint
  }
}

output "website_domains" {
  description = "Map of bucket keys to website domains (for buckets with website hosting enabled)"
  value = {
    for k, v in aws_s3_bucket_website_configuration.this :
    k => v.website_domain
  }
}

# -----------------------------------------------------------------------------
# Versioning Outputs
# -----------------------------------------------------------------------------

output "versioning_enabled" {
  description = "Map of bucket keys to versioning status"
  value = {
    for k, v in aws_s3_bucket.this :
    k => contains(keys(aws_s3_bucket_versioning.this), k)
  }
}

# -----------------------------------------------------------------------------
# Encryption Outputs
# -----------------------------------------------------------------------------

output "encryption_enabled" {
  description = "Map of bucket keys to encryption status"
  value = {
    for k, v in aws_s3_bucket.this :
    k => contains(keys(aws_s3_bucket_server_side_encryption_configuration.this), k)
  }
}

output "encryption_algorithms" {
  description = "Map of bucket keys to encryption algorithms (AES256 or aws:kms)"
  value = {
    for k, v in aws_s3_bucket_server_side_encryption_configuration.this :
    k => tolist(v.rule)[0].apply_server_side_encryption_by_default[0].sse_algorithm
  }
}

output "kms_key_ids" {
  description = "Map of bucket keys to KMS key IDs (for SSE-KMS encrypted buckets)"
  value = {
    for k, v in aws_s3_bucket_server_side_encryption_configuration.this :
    k => try(tolist(v.rule)[0].apply_server_side_encryption_by_default[0].kms_master_key_id, null)
  }
}

# -----------------------------------------------------------------------------
# Public Access Block Outputs
# -----------------------------------------------------------------------------

output "public_access_block_enabled" {
  description = "Map of bucket keys to public access block status"
  value = {
    for k, v in aws_s3_bucket.this :
    k => contains(keys(aws_s3_bucket_public_access_block.this), k)
  }
}

output "block_public_acls" {
  description = "Map of bucket keys to block_public_acls setting"
  value = {
    for k, v in aws_s3_bucket_public_access_block.this :
    k => v.block_public_acls
  }
}

output "block_public_policy" {
  description = "Map of bucket keys to block_public_policy setting"
  value = {
    for k, v in aws_s3_bucket_public_access_block.this :
    k => v.block_public_policy
  }
}

# -----------------------------------------------------------------------------
# Lifecycle Outputs
# -----------------------------------------------------------------------------

output "lifecycle_rules_count" {
  description = "Map of bucket keys to number of lifecycle rules configured"
  value = {
    for k, v in aws_s3_bucket.this :
    k => length(lookup(var.buckets[k], "lifecycle_rules", {}))
  }
}

# -----------------------------------------------------------------------------
# Acceleration Outputs
# -----------------------------------------------------------------------------

output "acceleration_status" {
  description = "Map of bucket keys to transfer acceleration status"
  value = {
    for k, v in aws_s3_bucket_accelerate_configuration.this :
    k => v.status
  }
}

output "acceleration_endpoints" {
  description = "Map of bucket keys to accelerated endpoints (for buckets with acceleration enabled)"
  value = {
    for k, v in aws_s3_bucket_accelerate_configuration.this :
    k => "${v.bucket}.s3-accelerate.amazonaws.com"
  }
}

# -----------------------------------------------------------------------------
# Logging Outputs
# -----------------------------------------------------------------------------

output "logging_enabled" {
  description = "Map of bucket keys to logging status"
  value = {
    for k, v in aws_s3_bucket.this :
    k => contains(keys(aws_s3_bucket_logging.this), k)
  }
}

output "logging_target_buckets" {
  description = "Map of bucket keys to logging target bucket names"
  value = {
    for k, v in aws_s3_bucket_logging.this :
    k => v.target_bucket
  }
}

# -----------------------------------------------------------------------------
# Replication Outputs
# -----------------------------------------------------------------------------

output "replication_enabled" {
  description = "Map of bucket keys to replication status"
  value = {
    for k, v in aws_s3_bucket.this :
    k => contains(keys(aws_s3_bucket_replication_configuration.this), k)
  }
}

output "replication_role_arns" {
  description = "Map of bucket keys to replication IAM role ARNs"
  value = {
    for k, v in aws_s3_bucket_replication_configuration.this :
    k => v.role
  }
}

# -----------------------------------------------------------------------------
# CORS Outputs
# -----------------------------------------------------------------------------

output "cors_rules_count" {
  description = "Map of bucket keys to number of CORS rules configured"
  value = {
    for k, v in aws_s3_bucket.this :
    k => length(lookup(var.buckets[k], "cors_rules", []))
  }
}

# -----------------------------------------------------------------------------
# Object Lock Outputs
# -----------------------------------------------------------------------------

output "object_lock_enabled" {
  description = "Map of bucket keys to object lock status"
  value = {
    for k, v in aws_s3_bucket.this :
    k => v.object_lock_enabled
  }
}

output "object_lock_configuration" {
  description = "Map of bucket keys to object lock retention configuration"
  value = {
    for k, v in aws_s3_bucket_object_lock_configuration.this :
    k => {
      mode = try(tolist(v.rule)[0].default_retention[0].mode, null)
      days = try(tolist(v.rule)[0].default_retention[0].days, null)
    }
  }
}

# -----------------------------------------------------------------------------
# Ownership Controls Outputs
# -----------------------------------------------------------------------------

output "object_ownership" {
  description = "Map of bucket keys to object ownership setting"
  value = {
    for k, v in aws_s3_bucket_ownership_controls.this :
    k => tolist(v.rule)[0].object_ownership
  }
}

# -----------------------------------------------------------------------------
# Request Payment Outputs
# -----------------------------------------------------------------------------

output "request_payer" {
  description = "Map of bucket keys to request payer setting"
  value = {
    for k, v in aws_s3_bucket_request_payment_configuration.this :
    k => v.payer
  }
}

# -----------------------------------------------------------------------------
# Notifications Outputs
# -----------------------------------------------------------------------------

output "notifications_enabled" {
  description = "Map of bucket keys to notifications status"
  value = {
    for k, v in aws_s3_bucket.this :
    k => contains(keys(aws_s3_bucket_notification.this), k)
  }
}

output "eventbridge_enabled" {
  description = "Map of bucket keys to EventBridge integration status"
  value = {
    for k, v in aws_s3_bucket_notification.this :
    k => try(v.eventbridge, false)
  }
}

# -----------------------------------------------------------------------------
# Advanced Features Outputs
# -----------------------------------------------------------------------------

output "intelligent_tiering_configs_count" {
  description = "Map of bucket keys to number of intelligent tiering configurations"
  value = {
    for k, v in aws_s3_bucket.this :
    k => length(lookup(var.buckets[k], "intelligent_tiering_configs", {}))
  }
}

output "inventory_configs_count" {
  description = "Map of bucket keys to number of inventory configurations"
  value = {
    for k, v in aws_s3_bucket.this :
    k => length(lookup(var.buckets[k], "inventory_configs", {}))
  }
}

output "analytics_configs_count" {
  description = "Map of bucket keys to number of analytics configurations"
  value = {
    for k, v in aws_s3_bucket.this :
    k => length(lookup(var.buckets[k], "analytics_configs", {}))
  }
}

output "metrics_configs_count" {
  description = "Map of bucket keys to number of metrics configurations"
  value = {
    for k, v in aws_s3_bucket.this :
    k => length(lookup(var.buckets[k], "metrics_configs", {}))
  }
}

# -----------------------------------------------------------------------------
# Policy Outputs
# -----------------------------------------------------------------------------

output "bucket_policy_enabled" {
  description = "Map of bucket keys to bucket policy status"
  value = {
    for k, v in aws_s3_bucket.this :
    k => contains(keys(aws_s3_bucket_policy.this), k)
  }
}

# -----------------------------------------------------------------------------
# Comprehensive Summary Output
# -----------------------------------------------------------------------------

output "buckets_summary" {
  description = "Comprehensive summary of all bucket configurations"
  value = {
    for k, v in aws_s3_bucket.this : k => {
      id                     = v.id
      arn                    = v.arn
      region                 = v.region
      domain_name            = v.bucket_domain_name
      versioning_enabled     = contains(keys(aws_s3_bucket_versioning.this), k)
      encryption_enabled     = contains(keys(aws_s3_bucket_server_side_encryption_configuration.this), k)
      website_enabled        = contains(keys(aws_s3_bucket_website_configuration.this), k)
      logging_enabled        = contains(keys(aws_s3_bucket_logging.this), k)
      replication_enabled    = contains(keys(aws_s3_bucket_replication_configuration.this), k)
      acceleration_enabled   = contains(keys(aws_s3_bucket_accelerate_configuration.this), k)
      object_lock_enabled    = v.object_lock_enabled
      public_access_blocked  = contains(keys(aws_s3_bucket_public_access_block.this), k)
      policy_attached        = contains(keys(aws_s3_bucket_policy.this), k)
      lifecycle_rules_count  = length(lookup(var.buckets[k], "lifecycle_rules", {}))
      cors_rules_count       = length(lookup(var.buckets[k], "cors_rules", []))
    }
  }
}
