# =============================================================================
# S3 Bucket Server-Side Encryption Configuration
# =============================================================================
# Configures server-side encryption for S3 buckets
# Supports SSE-S3 (AES256) and SSE-KMS encryption types

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = local.buckets_with_encryption

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      # SSE algorithm: "AES256" (SSE-S3) or "aws:kms" (SSE-KMS)
      sse_algorithm = each.value.encryption_type

      # KMS key ID/ARN - only used when encryption_type = "aws:kms"
      kms_master_key_id = each.value.encryption_type == "aws:kms" ? each.value.kms_key_id : null
    }

    # S3 Bucket Keys reduce KMS costs by decreasing API calls to KMS
    # Only applicable for SSE-KMS encryption
    bucket_key_enabled = each.value.encryption_type == "aws:kms" ? each.value.bucket_key_enabled : null
  }
}
