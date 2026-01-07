# =============================================================================
# Outputs - Static Website Example
# =============================================================================

output "website_bucket_id" {
  description = "The ID of the website bucket"
  value       = module.s3_buckets.bucket_ids["website"]
}

output "website_bucket_arn" {
  description = "The ARN of the website bucket"
  value       = module.s3_buckets.bucket_arns["website"]
}

output "website_endpoint" {
  description = "The website endpoint URL"
  value       = module.s3_buckets.website_endpoints["website"]
}

output "website_domain" {
  description = "The website domain"
  value       = module.s3_buckets.website_domains["website"]
}

output "website_url" {
  description = "Full website URL"
  value       = "http://${module.s3_buckets.website_endpoints["website"]}"
}

output "logs_bucket_id" {
  description = "The ID of the logs bucket"
  value       = module.s3_buckets.bucket_ids["website-logs"]
}

output "cors_rules_count" {
  description = "Number of CORS rules configured"
  value       = module.s3_buckets.cors_rules_count["website"]
}

output "deployment_instructions" {
  description = "Instructions for deploying website content"
  value       = <<-EOT
    Deploy your website using AWS CLI:

    # Upload all files from your website directory
    aws s3 sync ./website-content/ s3://${module.s3_buckets.bucket_ids["website"]}/ --delete

    # Upload a single file
    aws s3 cp index.html s3://${module.s3_buckets.bucket_ids["website"]}/

    # Set MIME types for specific files
    aws s3 cp styles.css s3://${module.s3_buckets.bucket_ids["website"]}/ --content-type text/css

    # Visit your website at:
    http://${module.s3_buckets.website_endpoints["website"]}
  EOT
}
