# =============================================================================
# S3 Bucket Inventory Configuration
# =============================================================================
# Configures S3 inventory reports for bucket auditing and analysis
# Generates CSV/ORC/Parquet reports with object metadata

resource "aws_s3_bucket_inventory" "this" {
  for_each = local.flattened_inventory_configs

  bucket = aws_s3_bucket.this[each.value.bucket_key].id
  name   = each.key

  # Inventory reports are placed in this bucket
  included_object_versions = each.value.included_object_versions

  # Schedule: Daily or Weekly
  schedule {
    frequency = each.value.frequency
  }

  # ---------------------------------------------------------------------------
  # Destination
  # ---------------------------------------------------------------------------
  # Where inventory reports are stored

  destination {
    bucket {
      format     = each.value.destination_format
      bucket_arn = each.value.destination_bucket_arn
      prefix     = each.value.destination_prefix

      # Optional: encrypt inventory reports with SSE-S3 or SSE-KMS
      dynamic "encryption" {
        for_each = each.value.destination_encryption_type != null ? [1] : []

        content {
          dynamic "sse_s3" {
            for_each = each.value.destination_encryption_type == "sse_s3" ? [1] : []
            content {}
          }

          dynamic "sse_kms" {
            for_each = each.value.destination_encryption_type == "sse_kms" ? [1] : []

            content {
              key_id = each.value.destination_kms_key_id
            }
          }
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Filter (Optional)
  # ---------------------------------------------------------------------------
  # Include only objects matching the prefix

  dynamic "filter" {
    for_each = each.value.filter_prefix != null ? [1] : []

    content {
      prefix = each.value.filter_prefix
    }
  }

  # ---------------------------------------------------------------------------
  # Optional Fields
  # ---------------------------------------------------------------------------
  # Additional metadata to include in inventory reports
  # Options: Size, LastModifiedDate, StorageClass, ETag, IsMultipartUploaded,
  # ReplicationStatus, EncryptionStatus, ObjectLockRetainUntilDate, etc.

  optional_fields = each.value.optional_fields
}
