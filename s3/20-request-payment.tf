# =============================================================================
# S3 Bucket Request Payment Configuration
# =============================================================================
# Configures who pays for S3 request and data transfer costs
# Useful for shared datasets where consumers should pay for their usage

resource "aws_s3_bucket_request_payment_configuration" "this" {
  for_each = local.buckets_with_request_payment

  bucket = aws_s3_bucket.this[each.key].id

  # Payer options:
  # - BucketOwner: Bucket owner pays (default)
  # - Requester: Requester pays (must be AWS authenticated)
  payer = each.value.request_payer
}
