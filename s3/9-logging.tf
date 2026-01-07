# =============================================================================
# S3 Bucket Logging Configuration
# =============================================================================
# Configures server access logging for S3 buckets
# Logs all requests made to the bucket for audit and analysis

resource "aws_s3_bucket_logging" "this" {
  for_each = local.buckets_with_logging

  bucket = aws_s3_bucket.this[each.key].id

  # Target bucket where access logs will be stored
  # Must be in the same region and have proper bucket policy
  target_bucket = each.value.logging_config.target_bucket

  # Prefix for log objects (e.g., "logs/" or "access-logs/mybucket/")
  # Helps organize logs when multiple buckets log to the same target
  target_prefix = each.value.logging_config.target_prefix
}
