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

      # -----------------------------------------------------------------------
      # Schema selection
      # -----------------------------------------------------------------------
      # V1 (legacy): no filter, no priority, no delete_marker_replication.
      # V2: used automatically when the rule sets a filter or enables delete
      # marker replication. AWS requires DeleteMarkerReplication (and accepts
      # Priority) whenever a Filter is present, so both are emitted for V2.
      # Rules without filter and without delete marker replication keep V1,
      # so existing configurations do not change.

      priority = (
        rule.value.filter_prefix != null ||
        rule.value.filter_tags != null ||
        rule.value.delete_marker_replication_enabled
      ) ? rule.value.priority : null

      dynamic "delete_marker_replication" {
        for_each = (
          rule.value.filter_prefix != null ||
          rule.value.filter_tags != null ||
          rule.value.delete_marker_replication_enabled
        ) ? [1] : []

        content {
          status = rule.value.delete_marker_replication_enabled ? "Enabled" : "Disabled"
        }
      }

      # -----------------------------------------------------------------------
      # Filter
      # -----------------------------------------------------------------------
      # Determines which objects to replicate (empty filter = whole bucket, V2)

      dynamic "filter" {
        for_each = (
          rule.value.filter_prefix != null ||
          rule.value.filter_tags != null ||
          rule.value.delete_marker_replication_enabled
        ) ? [1] : []

        content {
          # Simple prefix filter (when no tags specified)
          prefix = rule.value.filter_prefix != null && rule.value.filter_tags == null ? rule.value.filter_prefix : null

          # Replicate only objects matching prefix AND tags (or several tags)
          dynamic "and" {
            for_each = (
              (rule.value.filter_prefix != null ? 1 : 0) +
              (rule.value.filter_tags != null ? length(rule.value.filter_tags) : 0)
            ) > 1 && rule.value.filter_tags != null ? [1] : []

            content {
              prefix = rule.value.filter_prefix
              tags   = rule.value.filter_tags
            }
          }

          # Replicate only objects with this single tag (no prefix)
          dynamic "tag" {
            for_each = rule.value.filter_prefix == null && rule.value.filter_tags != null && try(length(rule.value.filter_tags), 0) == 1 ? rule.value.filter_tags : {}

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

        # Destination account (cross-account replication)
        account = rule.value.destination_account_id

        # Change replica ownership to the destination account (cross-account)
        dynamic "access_control_translation" {
          for_each = rule.value.destination_access_control_translation != null ? [rule.value.destination_access_control_translation] : []

          content {
            owner = access_control_translation.value.owner
          }
        }

        # KMS key used to encrypt replicas in the destination
        dynamic "encryption_configuration" {
          for_each = rule.value.destination_replica_kms_key_id != null ? [1] : []

          content {
            replica_kms_key_id = rule.value.destination_replica_kms_key_id
          }
        }

        # Replication metrics for monitoring (optional)
        dynamic "metrics" {
          for_each = rule.value.metrics_enabled ? [1] : []

          content {
            status = "Enabled"

            event_threshold {
              # Emit metrics for objects that take longer than N minutes
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
