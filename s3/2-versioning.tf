# =============================================================================
# S3 Bucket Versioning Configuration
# =============================================================================
# Enables versioning on S3 buckets for data protection and recovery
# Versioning allows you to preserve, retrieve, and restore every version of every object

resource "aws_s3_bucket_versioning" "this" {
  for_each = local.buckets_with_versioning

  bucket = aws_s3_bucket.this[each.key].id

  versioning_configuration {
    status = "Enabled"

    # MFA delete requires MFA authentication for permanent deletion of object versions
    # Can only be enabled by the bucket owner using the root account
    mfa_delete = each.value.versioning_mfa_delete ? "Enabled" : "Disabled"
  }
}
