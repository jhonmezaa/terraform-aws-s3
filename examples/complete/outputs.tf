output "all_bucket_ids" {
  description = "All bucket IDs"
  value       = module.s3_buckets.bucket_ids
}

output "all_bucket_arns" {
  description = "All bucket ARNs"
  value       = module.s3_buckets.bucket_arns
}

output "buckets_summary" {
  description = "Complete summary of all buckets"
  value       = module.s3_buckets.buckets_summary
}

output "complete_bucket_features" {
  description = "Detailed feature status for complete bucket"
  value = {
    id                        = module.s3_buckets.bucket_ids["complete"]
    arn                       = module.s3_buckets.bucket_arns["complete"]
    versioning_enabled        = module.s3_buckets.versioning_enabled["complete"]
    encryption_enabled        = module.s3_buckets.encryption_enabled["complete"]
    encryption_algorithm      = module.s3_buckets.encryption_algorithms["complete"]
    acceleration_enabled      = contains(keys(module.s3_buckets.acceleration_status), "complete")
    acceleration_endpoint     = try(module.s3_buckets.acceleration_endpoints["complete"], null)
    lifecycle_rules_count     = module.s3_buckets.lifecycle_rules_count["complete"]
    intelligent_tiering_count = module.s3_buckets.intelligent_tiering_configs_count["complete"]
    inventory_configs_count   = module.s3_buckets.inventory_configs_count["complete"]
    analytics_configs_count   = module.s3_buckets.analytics_configs_count["complete"]
    metrics_configs_count     = module.s3_buckets.metrics_configs_count["complete"]
    notifications_enabled     = module.s3_buckets.notifications_enabled["complete"]
    eventbridge_enabled       = contains(keys(module.s3_buckets.eventbridge_enabled), "complete") ? module.s3_buckets.eventbridge_enabled["complete"] : false
    public_access_blocked     = module.s3_buckets.public_access_block_enabled["complete"]
    object_ownership          = try(module.s3_buckets.object_ownership["complete"], null)
  }
}

output "compliance_bucket_features" {
  description = "Detailed feature status for compliance bucket"
  value = {
    id                  = module.s3_buckets.bucket_ids["compliance"]
    arn                 = module.s3_buckets.bucket_arns["compliance"]
    object_lock_enabled = module.s3_buckets.object_lock_enabled["compliance"]
    object_lock_config  = try(module.s3_buckets.object_lock_configuration["compliance"], null)
    versioning_enabled  = module.s3_buckets.versioning_enabled["compliance"]
  }
}
