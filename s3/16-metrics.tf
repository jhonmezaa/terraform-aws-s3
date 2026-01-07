# =============================================================================
# S3 Bucket Metrics Configuration
# =============================================================================
# Configures S3 request metrics for CloudWatch monitoring
# Provides detailed metrics for filtered subsets of objects

resource "aws_s3_bucket_metric" "this" {
  for_each = local.flattened_metrics_configs

  bucket = aws_s3_bucket.this[each.value.bucket_key].id
  name   = each.key

  # ---------------------------------------------------------------------------
  # Filter (Optional)
  # ---------------------------------------------------------------------------
  # Collect metrics only for objects matching prefix, tags, or access point

  dynamic "filter" {
    for_each = (
      each.value.filter_prefix != null ||
      each.value.filter_tags != null ||
      each.value.filter_access_point_arn != null
    ) ? [1] : []

    content {
      # Filter by object prefix
      prefix = each.value.filter_prefix

      # Filter by object tags
      tags = each.value.filter_tags

      # Filter by S3 Access Point ARN
      access_point = each.value.filter_access_point_arn
    }
  }
}
