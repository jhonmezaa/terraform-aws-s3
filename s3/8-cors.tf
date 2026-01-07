# =============================================================================
# S3 Bucket CORS Configuration
# =============================================================================
# Configures Cross-Origin Resource Sharing (CORS) rules
# Required for web applications accessing S3 from different domains

resource "aws_s3_bucket_cors_configuration" "this" {
  for_each = local.buckets_with_cors

  bucket = aws_s3_bucket.this[each.key].id

  # ---------------------------------------------------------------------------
  # CORS Rules
  # ---------------------------------------------------------------------------
  # Each rule defines which origins, methods, and headers are allowed

  dynamic "cors_rule" {
    for_each = each.value.cors_rules

    content {
      # Origins allowed to access the bucket (e.g., ["https://example.com"])
      allowed_origins = cors_rule.value.allowed_origins

      # HTTP methods allowed (e.g., ["GET", "POST", "PUT", "DELETE"])
      allowed_methods = cors_rule.value.allowed_methods

      # Headers allowed in preflight requests (e.g., ["*"], ["Authorization"])
      allowed_headers = cors_rule.value.allowed_headers

      # Headers exposed to the browser (e.g., ["ETag", "x-amz-request-id"])
      expose_headers = cors_rule.value.expose_headers

      # How long (in seconds) the browser should cache preflight response
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}
