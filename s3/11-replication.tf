# =============================================================================
# S3 Bucket Replication Configuration
# =============================================================================
# Configures Cross-Region Replication (CRR) or Same-Region Replication (SRR)
# Automatically replicates objects to destination bucket(s)
# Requires versioning enabled on both source and destination buckets

resource "aws_s3_bucket_replication_configuration" "this" {
  for_each = local.buckets_with_replication

  bucket = aws_s3_bucket.this[each.key].id

  # IAM role that S3 assumes to replicate objects
  # Role must have permissions to read from source and write to destination
  role = each.value.replication_config.role_arn

  # Dependency: Ensure versioning is enabled before applying replication
  depends_on = [aws_s3_bucket_versioning.this]

  # ---------------------------------------------------------------------------
  # Replication Rules
  # ---------------------------------------------------------------------------
  # Multiple rules allow selective replication based on filters

  dynamic "rule" {
    for_each = each.value.replication_config.rules

    content {
      id     = rule.key
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # Priority (COMMENTED OUT - Schema version incompatibility)
      # AWS Error: "Priority cannot be used for this version of Cross Region Replication configuration schema"
      # priority = rule.value.priority

      # -----------------------------------------------------------------------
      # Filter
      # -----------------------------------------------------------------------
      # Determines which objects to replicate

      dynamic "filter" {
        for_each = rule.value.filter_prefix != null || rule.value.filter_tags != null ? [1] : []

        content {
          # Simple prefix filter (when no tags specified)
          prefix = rule.value.filter_prefix != null && rule.value.filter_tags == null ? rule.value.filter_prefix : null

          # Replicate only objects matching prefix AND tags
          dynamic "and" {
            for_each = rule.value.filter_prefix != null && rule.value.filter_tags != null ? [1] : []

            content {
              prefix = rule.value.filter_prefix
              tags   = rule.value.filter_tags
            }
          }

          # Replicate only objects with these tags (no prefix)
          dynamic "tag" {
            for_each = rule.value.filter_prefix == null && rule.value.filter_tags != null ? rule.value.filter_tags : {}

            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      # -----------------------------------------------------------------------
      # Destination
      # -----------------------------------------------------------------------
      # Where to replicate objects

      destination {
        # Destination bucket ARN
        bucket = rule.value.destination_bucket

        # Storage class for replicated objects (optional)
        # Options: STANDARD, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE
        storage_class = rule.value.destination_storage_class

        # Replication metrics for monitoring (optional)
        dynamic "metrics" {
          for_each = rule.value.metrics_enabled ? [1] : []

          content {
            status = "Enabled"

            event_threshold {
              # Emit metrics for objects that take longer than 15 minutes
              minutes = rule.value.metrics_minutes
            }
          }
        }

        # Replication Time Control (RTC) for predictable replication time (optional)
        dynamic "replication_time" {
          for_each = rule.value.replication_time_control_enabled ? [1] : []

          content {
            status = "Enabled"

            time {
              # Replicate within 15 minutes (AWS SLA)
              minutes = rule.value.replication_time_minutes
            }
          }
        }
      }

      # -----------------------------------------------------------------------
      # Delete Marker Replication (COMMENTED OUT - Schema version incompatibility)
      # -----------------------------------------------------------------------
      # Whether to replicate delete markers (when objects are deleted)
      # Note: This feature requires newer replication schema version
      # Temporarily disabled due to AWS error:
      # "DeleteMarkerReplication cannot be used for this version of Cross Region Replication configuration schema"
      #
      # dynamic "delete_marker_replication" {
      #   for_each = rule.value.delete_marker_replication_enabled ? [1] : []
      #
      #   content {
      #     status = "Enabled"
      #   }
      # }

      # -----------------------------------------------------------------------
      # Source Selection Criteria (Optional)
      # -----------------------------------------------------------------------
      # Replicate objects encrypted with SSE-KMS

      dynamic "source_selection_criteria" {
        for_each = rule.value.source_selection_criteria_sse_kms_encrypted_objects ? [1] : []

        content {
          sse_kms_encrypted_objects {
            status = "Enabled"
          }
        }
      }
    }
  }
}
