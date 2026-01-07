# =============================================================================
# S3 Bucket Analytics Configuration
# =============================================================================
# Configures S3 storage class analysis for lifecycle optimization
# Analyzes access patterns to recommend lifecycle transitions

resource "aws_s3_bucket_analytics_configuration" "this" {
  for_each = local.flattened_analytics_configs

  bucket = aws_s3_bucket.this[each.value.bucket_key].id
  name   = each.key

  # ---------------------------------------------------------------------------
  # Storage Class Analysis
  # ---------------------------------------------------------------------------
  # Analyzes objects to determine optimal storage class transitions

  dynamic "storage_class_analysis" {
    for_each = each.value.export_destination_bucket_arn != null ? [1] : []

    content {
      data_export {
        destination {
          s3_bucket_destination {
            bucket_arn = each.value.export_destination_bucket_arn
            prefix     = each.value.export_destination_prefix
            format     = "CSV"
          }
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Filter (Optional)
  # ---------------------------------------------------------------------------
  # Analyze only objects matching prefix and/or tags

  dynamic "filter" {
    for_each = each.value.filter_prefix != null || each.value.filter_tags != null ? [1] : []

    content {
      prefix = each.value.filter_prefix
      tags   = each.value.filter_tags
    }
  }
}
