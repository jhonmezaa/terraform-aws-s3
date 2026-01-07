output "elb_logs_bucket" {
  description = "ELB logs bucket name"
  value       = module.s3_buckets.bucket_ids["elb-logs"]
}

output "cloudtrail_logs_bucket" {
  description = "CloudTrail logs bucket name"
  value       = module.s3_buckets.bucket_ids["cloudtrail-logs"]
}

output "waf_logs_bucket" {
  description = "WAF logs bucket name"
  value       = module.s3_buckets.bucket_ids["waf-logs"]
}

output "app_logs_bucket" {
  description = "Application logs bucket name"
  value       = module.s3_buckets.bucket_ids["app-logs"]
}

output "bucket_arns" {
  description = "All bucket ARNs"
  value       = module.s3_buckets.bucket_arns
}
