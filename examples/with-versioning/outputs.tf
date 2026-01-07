# =============================================================================
# Outputs - Versioning Example
# =============================================================================

output "bucket_ids" {
  description = "Map of bucket keys to IDs"
  value       = module.s3_buckets.bucket_ids
}

output "bucket_arns" {
  description = "Map of bucket keys to ARNs"
  value       = module.s3_buckets.bucket_arns
}

output "versioning_enabled" {
  description = "Map of bucket keys to versioning status"
  value       = module.s3_buckets.versioning_enabled
}

output "lifecycle_rules_count" {
  description = "Map of bucket keys to number of lifecycle rules"
  value       = module.s3_buckets.lifecycle_rules_count
}

output "buckets_summary" {
  description = "Comprehensive summary of all bucket configurations"
  value       = module.s3_buckets.buckets_summary
}
