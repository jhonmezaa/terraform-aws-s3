# =============================================================================
# S3 Bucket Object Lock Configuration
# =============================================================================
# Configures object lock settings for compliance and data retention
# Prevents objects from being deleted or overwritten for a fixed time or indefinitely
# Note: object_lock_enabled must be set to true at bucket creation (cannot be changed later)

resource "aws_s3_bucket_object_lock_configuration" "this" {
  for_each = local.buckets_with_object_lock_config

  bucket = aws_s3_bucket.this[each.key].id

  # Object lock must be enabled on the bucket
  # This is set in 1-bucket.tf via object_lock_enabled parameter

  # ---------------------------------------------------------------------------
  # Default Retention Rule
  # ---------------------------------------------------------------------------
  # Applies to all objects unless overridden at object level

  dynamic "rule" {
    for_each = each.value.object_lock_config.rule_default_retention_mode != null ? [1] : []

    content {
      default_retention {
        # Retention mode:
        # - GOVERNANCE: Can be removed by users with special permissions
        # - COMPLIANCE: Cannot be removed by anyone, including root account
        mode = each.value.object_lock_config.rule_default_retention_mode

        # Retention period in days
        days = each.value.object_lock_config.rule_default_retention_days

        # Alternative: specify years instead of days
        # years = each.value.object_lock_config.rule_default_retention_years
      }
    }
  }
}
