# =============================================================================
# S3 Bucket Accelerate Configuration
# =============================================================================
# Configures S3 Transfer Acceleration for faster uploads/downloads
# Uses AWS CloudFront edge locations to optimize transfer speeds

resource "aws_s3_bucket_accelerate_configuration" "this" {
  for_each = local.buckets_with_acceleration

  bucket = aws_s3_bucket.this[each.key].id

  # Transfer acceleration status: "Enabled" or "Suspended"
  # When enabled, provides accelerated endpoint: bucketname.s3-accelerate.amazonaws.com
  status = "Enabled"
}
