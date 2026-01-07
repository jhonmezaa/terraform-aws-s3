# =============================================================================
# S3 Bucket Intelligent-Tiering Configuration
# =============================================================================
# Configures S3 Intelligent-Tiering archive configurations
# Automatically moves objects to Archive Access or Deep Archive Access tiers
# Provides additional cost savings beyond standard Intelligent-Tiering

resource "aws_s3_bucket_intelligent_tiering_configuration" "this" {
  for_each = local.flattened_intelligent_tiering_configs

  bucket = aws_s3_bucket.this[each.value.bucket_key].id
  name   = each.key

  # Status: Enabled or Disabled
  status = each.value.status

  # ---------------------------------------------------------------------------
  # Filter (Optional)
  # ---------------------------------------------------------------------------
  # Apply tiering only to objects matching the filter

  dynamic "filter" {
    for_each = each.value.filter_prefix != null || each.value.filter_tags != null ? [1] : []

    content {
      prefix = each.value.filter_prefix
      tags   = each.value.filter_tags
    }
  }

  # ---------------------------------------------------------------------------
  # Tiering Configurations
  # ---------------------------------------------------------------------------
  # Define when objects transition to archive tiers
  # ARCHIVE_ACCESS: 90-730 days without access
  # DEEP_ARCHIVE_ACCESS: 180-730 days without access

  dynamic "tiering" {
    for_each = each.value.tierings

    content {
      # Access tier: ARCHIVE_ACCESS or DEEP_ARCHIVE_ACCESS
      access_tier = tiering.value.access_tier

      # Days without access before transitioning
      days = tiering.value.days
    }
  }
}
