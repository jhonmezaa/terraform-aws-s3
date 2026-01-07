# =============================================================================
# Outputs - Simple Example
# =============================================================================

output "bucket_id" {
  description = "The ID (name) of the created S3 bucket"
  value       = module.s3_buckets.bucket_ids["data"]
}

output "bucket_arn" {
  description = "The ARN of the created S3 bucket"
  value       = module.s3_buckets.bucket_arns["data"]
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = module.s3_buckets.bucket_domain_names["data"]
}

output "bucket_region" {
  description = "The AWS region of the bucket"
  value       = module.s3_buckets.bucket_regions["data"]
}

output "versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = module.s3_buckets.versioning_enabled["data"]
}

output "encryption_enabled" {
  description = "Whether encryption is enabled"
  value       = module.s3_buckets.encryption_enabled["data"]
}

output "encryption_algorithm" {
  description = "The encryption algorithm used"
  value       = module.s3_buckets.encryption_algorithms["data"]
}

output "public_access_blocked" {
  description = "Whether public access is blocked"
  value       = module.s3_buckets.public_access_block_enabled["data"]
}

output "bucket_summary" {
  description = "Comprehensive summary of the bucket configuration"
  value       = module.s3_buckets.buckets_summary["data"]
}
