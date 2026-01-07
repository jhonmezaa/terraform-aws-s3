# =============================================================================
# S3 Bucket ACL
# =============================================================================
# Configures bucket Access Control List (ACL)
# Note: Only applicable when object_ownership != "BucketOwnerEnforced"
# AWS recommends using bucket policies instead of ACLs

resource "aws_s3_bucket_acl" "this" {
  for_each = local.buckets_with_acl

  bucket = aws_s3_bucket.this[each.key].id

  # Canned ACL options:
  # - private: Owner gets FULL_CONTROL (default)
  # - public-read: Owner gets FULL_CONTROL, AllUsers get READ
  # - public-read-write: Owner gets FULL_CONTROL, AllUsers get READ and WRITE
  # - authenticated-read: Owner gets FULL_CONTROL, AuthenticatedUsers get READ
  # - log-delivery-write: LogDelivery group gets WRITE and READ_ACP
  acl = each.value.acl

  # Dependency: Must be set after ownership controls
  depends_on = [aws_s3_bucket_ownership_controls.this]
}
