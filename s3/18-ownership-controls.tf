# =============================================================================
# S3 Bucket Ownership Controls
# =============================================================================
# Configures object ownership for uploaded objects
# Controls whether bucket owner automatically owns objects uploaded by other accounts

resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = local.buckets_with_ownership_controls

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    # Object ownership options:
    # - BucketOwnerEnforced: Bucket owner owns all objects (recommended, disables ACLs)
    # - BucketOwnerPreferred: Bucket owner owns objects if uploader grants full control
    # - ObjectWriter: Object uploader retains ownership
    object_ownership = each.value.object_ownership
  }
}
