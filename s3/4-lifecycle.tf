# =============================================================================
# S3 Bucket Lifecycle Configuration
# =============================================================================
# Manages object lifecycle rules including:
# - Transitions between storage classes (STANDARD → STANDARD_IA → GLACIER → DEEP_ARCHIVE)
# - Expiration of current and noncurrent versions
# - Abort incomplete multipart uploads
# - Advanced filtering by prefix, tags, and object size

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = {
    for k, v in var.buckets :
    k => v if length(v.lifecycle_rules) > 0
  }

  bucket = aws_s3_bucket.this[each.key].id

  # Dynamic rule blocks - one for each lifecycle rule defined
  dynamic "rule" {
    for_each = each.value.lifecycle_rules

    content {
      id     = rule.key
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # -----------------------------------------------------------------------
      # Filter Block
      # -----------------------------------------------------------------------
      # Filters determine which objects the rule applies to
      # Can filter by prefix, tags, object size, or combinations
      # IMPORTANT: AWS Provider requires a filter block (even if empty)

      filter {
        # Use "and" block when multiple filter criteria are specified
        dynamic "and" {
          for_each = (
            (rule.value.filter_tags != null ||
              rule.value.filter_object_size_greater_than != null ||
            rule.value.filter_object_size_less_than != null) &&
            rule.value.filter_prefix != null
          ) ? [1] : []

          content {
            prefix                   = rule.value.filter_prefix
            tags                     = rule.value.filter_tags
            object_size_greater_than = rule.value.filter_object_size_greater_than
            object_size_less_than    = rule.value.filter_object_size_less_than
          }
        }

        # Simple prefix filter (when no other criteria)
        prefix = (
          rule.value.filter_prefix != null &&
          rule.value.filter_tags == null &&
          rule.value.filter_object_size_greater_than == null &&
          rule.value.filter_object_size_less_than == null
        ) ? rule.value.filter_prefix : null

        # Simple object size greater than filter (when no other criteria)
        object_size_greater_than = (
          rule.value.filter_object_size_greater_than != null &&
          rule.value.filter_prefix == null &&
          rule.value.filter_tags == null &&
          rule.value.filter_object_size_less_than == null
        ) ? rule.value.filter_object_size_greater_than : null

        # Simple object size less than filter (when no other criteria)
        object_size_less_than = (
          rule.value.filter_object_size_less_than != null &&
          rule.value.filter_prefix == null &&
          rule.value.filter_tags == null &&
          rule.value.filter_object_size_greater_than == null
        ) ? rule.value.filter_object_size_less_than : null

        # Simple tag filter (when no other criteria)
        dynamic "tag" {
          for_each = (
            rule.value.filter_tags != null &&
            rule.value.filter_prefix == null &&
            rule.value.filter_object_size_greater_than == null &&
            rule.value.filter_object_size_less_than == null
          ) ? rule.value.filter_tags : {}

          content {
            key   = tag.key
            value = tag.value
          }
        }
      }

      # -----------------------------------------------------------------------
      # Current Version Transitions
      # -----------------------------------------------------------------------
      # Transitions move objects to lower-cost storage classes over time
      # Example: STANDARD → STANDARD_IA (30 days) → GLACIER (90 days)

      dynamic "transition" {
        for_each = rule.value.transitions

        content {
          days          = transition.value.days
          date          = transition.value.date
          storage_class = transition.value.storage_class
        }
      }

      # -----------------------------------------------------------------------
      # Noncurrent Version Transitions
      # -----------------------------------------------------------------------
      # Transitions for previous versions of objects (when versioning enabled)

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions

        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      # -----------------------------------------------------------------------
      # Current Version Expiration
      # -----------------------------------------------------------------------
      # Permanently deletes objects after specified time
      # NOTE: Only ONE of days/date/expired_object_delete_marker can be specified

      dynamic "expiration" {
        for_each = (
          rule.value.expiration_days != null ||
          rule.value.expiration_date != null ||
          rule.value.expiration_expired_object_delete_marker
        ) ? [1] : []

        content {
          # Only specify the attribute that has a value (AWS allows only one)
          days                         = rule.value.expiration_expired_object_delete_marker ? null : rule.value.expiration_days
          date                         = rule.value.expiration_expired_object_delete_marker ? null : rule.value.expiration_date
          expired_object_delete_marker = rule.value.expiration_expired_object_delete_marker ? true : null
        }
      }

      # -----------------------------------------------------------------------
      # Noncurrent Version Expiration
      # -----------------------------------------------------------------------
      # Permanently deletes old versions of objects

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days != null ? [1] : []

        content {
          noncurrent_days = rule.value.noncurrent_version_expiration_days

          # Keep only N newest noncurrent versions
          newer_noncurrent_versions = rule.value.noncurrent_version_newer_versions
        }
      }

      # -----------------------------------------------------------------------
      # Abort Incomplete Multipart Uploads
      # -----------------------------------------------------------------------
      # Cleans up incomplete multipart uploads to reduce storage costs

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [1] : []

        content {
          days_after_initiation = rule.value.abort_incomplete_multipart_upload_days
        }
      }
    }
  }
}
